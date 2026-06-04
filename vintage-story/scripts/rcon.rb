#!/usr/bin/env ruby
# frozen_string_literal: true

# Safe RCON dispatcher for the Vintage Story server.
#
# This is the ONLY RCON path. There is no raw passthrough: the dispatcher maps a
# fixed set of safe subcommands to literal server commands and rejects anything
# else before a socket is opened. Destructive commands (/db prune, /wgen regen,
# /ban, /kick, /role set, ...) cannot be expressed through this script. The one
# exception is `stop` (server shutdown -> Host Havoc auto-restarts), exposed
# deliberately as the restart path.
#
# Usage:
#   rcon.rb list <clients|banned|roles|privileges>   # the server requires the arg
#   rcon.rb info [ident|seed|createdversion|mapsize]
#   rcon.rb time | stats | weather | help
#   rcon.rb mods                  # /moddb list
#   rcon.rb wc <field>            # READ a worldconfig value
#   rcon.rb wc-set <field> <val>  # WRITE one worldconfig value (hook-gated)
#   rcon.rb wc-dump [outfile]     # READ every worldconfig field -> typed JSON
#   rcon.rb autosavenow | genbackup [name]
#   rcon.rb stop                  # /stop — shuts the server down; Host Havoc auto-restarts
#   rcon.rb --selftest            # run the in-file dispatcher tests
#
# wc-dump exists because a world's WorldConfiguration is baked into the savegame
# DB at creation; serverconfig.json is only a creation-time seed, so live values
# can only be read back over RCON.
require 'socket'
require 'json'
require_relative 'lib'

module Rcon
  AUTH = 3
  EXECCOMMAND = 2
  RESPONSE_VALUE = 0
  AUTH_RESPONSE = 2 # same id as EXECCOMMAND in the Source RCON spec

  LIST_SUBS = %w[clients banned roles privileges].freeze # server wants "roles" (plural), not "role"
  INFO_SUBS = %w[ident seed createdversion mapsize].freeze
  NOARG = %w[time stats weather help autosavenow].freeze
  FIELD = /\A[A-Za-z0-9_]+\z/                     # one worldconfig key, no spaces
  BACKUP_NAME = /\A[A-Za-z0-9._-]+\z/             # one backup filename
  WC_VALUE = /\A[A-Za-z0-9._-]+\z/                # one worldconfig value, no spaces
  VALUE_RE = /currently has value:\s*(.*?)\s*\z/m
  CANON = File.join(VS::ROOT, 'configs', 'serverconfig.json')

  # Raised when an invocation is not in the safe set. Never reaches the server.
  class Reject < StandardError
    attr_reader :code

    def initialize(message, code = 3)
      super(message)
      @code = code
    end
  end

  module_function

  # --- Source RCON wire protocol (internal; no generalist entry point) --------

  def pack(req_id, ptype, body)
    payload = [req_id, ptype, body, 0, 0].pack('l<l<a*CC') # int32 id, int32 type, body, 2 nulls
    [payload.bytesize, payload].pack('l<a*')               # length-prefixed
  end

  def recv_exact(sock, count)
    buf = +''
    while buf.bytesize < count
      chunk = sock.read(count - buf.bytesize)
      raise IOError, 'connection closed mid-packet' if chunk.nil? || chunk.empty?

      buf << chunk
    end
    buf
  end

  def recv_packet(sock)
    size = recv_exact(sock, 4).unpack1('l<')
    data = recv_exact(sock, size)
    req_id, ptype = data[0, 8].unpack('l<l<')
    [req_id, ptype, data[8...-2]] # strip two trailing nulls
  end

  def send_cmd(cmd)
    host = VS.env['RCON_HOST'] || VS.env['SFTP_HOST']
    raise 'RCON_HOST or SFTP_HOST must be set' unless host

    port = Integer(VS.env['RCON_PORT'] || '42425')
    timeout = Float(VS.env['RCON_TIMEOUT'] || '10')
    sock = Socket.tcp(host, port, connect_timeout: timeout)
    sock.timeout = timeout if sock.respond_to?(:timeout=)
    begin
      authenticate(sock, VS.fetch('RCON_PASS'))
      sock.write(pack(2, EXECCOMMAND, cmd))
      sock.write(pack(3, RESPONSE_VALUE, '')) # end-marker: echoes after the real reply
      collect_reply(sock)
    ensure
      sock.close
    end
  end

  def authenticate(sock, password)
    sock.write(pack(1, AUTH, password))
    loop do
      req_id, ptype, = recv_packet(sock)
      next unless ptype == AUTH_RESPONSE
      raise 'RCON auth failed (bad password)' if req_id == -1

      break
    end
  end

  def collect_reply(sock)
    out = +''
    loop do
      req_id, _ptype, body = recv_packet(sock)
      break if req_id == 3 && (body.nil? || body.empty?)

      out << body
    end
    out.force_encoding('UTF-8')
  end

  # --- Safe dispatcher --------------------------------------------------------

  def resolve(argv)
    raise Reject.new('usage: rcon.rb <subcommand> [args] (try --selftest)', 2) if argv.empty?

    sub, *rest = argv
    case sub
    when 'list' then one_of('list', rest, LIST_SUBS)
    when 'info' then one_of('info', rest, INFO_SUBS)
    when *NOARG then no_args(sub, rest)
    when 'mods' then no_args(sub, rest, command: 'moddb list')
    when 'stop' then no_args(sub, rest, command: 'stop') # server shutdown; HH auto-restarts
    when 'wc' then resolve_wc(rest)
    when 'wc-set' then resolve_wc_set(rest)
    when 'genbackup' then resolve_genbackup(rest)
    else raise Reject, "unknown or disallowed subcommand: #{sub.inspect}"
    end
  end

  def one_of(cmd, rest, allowed)
    return cmd if rest.empty?
    return "#{cmd} #{rest[0]}" if rest.length == 1 && allowed.include?(rest[0])

    raise Reject, "#{cmd} takes one of: #{allowed.join(' ')}"
  end

  def no_args(sub, rest, command: nil)
    raise Reject, "#{sub} takes no arguments" unless rest.empty?

    command || sub
  end

  def resolve_wc(rest)
    return "worldconfig #{rest[0]}" if rest.length == 1 && rest[0].match?(FIELD)

    raise Reject, 'usage: wc <field> — read-only: one [A-Za-z0-9_] field, no value'
  end

  def resolve_wc_set(rest)
    # The one worldconfig write path: one field + one value, both charset-locked
    # so nothing else can be smuggled in. The vs-guard hook blocks this in auto mode.
    if rest.length == 2 && rest[0].match?(FIELD) && rest[1].match?(WC_VALUE)
      return "worldconfig #{rest[0]} #{rest[1]}"
    end

    raise Reject, 'usage: wc-set <field> <value> — one [A-Za-z0-9_] field, one [A-Za-z0-9._-] value'
  end

  def resolve_genbackup(rest)
    return 'genbackup' if rest.empty?
    return "genbackup #{rest[0]}" if rest.length == 1 && rest[0].match?(BACKUP_NAME)

    raise Reject, 'usage: genbackup [name] — name is [A-Za-z0-9._-] only'
  end

  # --- bulk worldconfig pull --------------------------------------------------

  # Parse a `/worldconfig <field>` reply into a value typed like canon_val.
  # Returns nil if the reply has no value marker, so an unreadable field shows
  # up as drift rather than a silent default.
  def parse_wc_value(reply, canon_val)
    match = VALUE_RE.match(reply.strip)
    return nil unless match

    raw = match[1].strip
    case canon_val
    when true, false then raw == 'True'
    when Integer then Integer(raw, exception: false) || raw
    when Float then Float(raw, exception: false) || raw
    else raw
    end
  end

  def wc_dump(outfile = nil)
    canon = JSON.parse(File.read(CANON))['WorldConfig']['WorldConfiguration']
    live = {}
    errors = {}
    canon.each_key do |field|
      reply = send_cmd(resolve(['wc', field]))
      live[field] = parse_wc_value(reply, canon[field])
    rescue StandardError => e
      errors[field] = e.message
    end

    write_dump(live, outfile)
    report_drift(canon, live)
    report_errors(errors)
  end

  def write_dump(live, outfile)
    out = JSON.pretty_generate(live)
    outfile ? File.write(outfile, "#{out}\n") : puts(out)
  end

  def report_drift(canon, live)
    drift = canon.keys.reject { |k| canon[k] == live[k] }
    warn ''
    if drift.empty?
      warn 'No drift: live matches canonical.'
      return
    end
    warn "DRIFT: #{drift.length} field(s) differ (canonical -> live):"
    width = drift.map(&:length).max
    drift.each do |k|
      warn format("  %-#{width}s  %12s -> %s", k, canon[k].inspect, live[k].inspect)
    end
  end

  def report_errors(errors)
    return 0 if errors.empty?

    warn "\n#{errors.length} field(s) failed to read:"
    errors.each { |k, e| warn "  #{k}: #{e}" }
    1
  end

  # --- In-file tests ----------------------------------------------------------

  def selftest
    ok = {
      %w[list] => 'list',
      %w[list clients] => 'list clients',
      %w[list roles] => 'list roles',
      %w[list privileges] => 'list privileges',
      %w[info] => 'info',
      %w[info seed] => 'info seed',
      %w[time] => 'time',
      %w[stats] => 'stats',
      %w[weather] => 'weather',
      %w[help] => 'help',
      %w[autosavenow] => 'autosavenow',
      %w[mods] => 'moddb list',
      %w[stop] => 'stop',
      %w[wc temporalStability] => 'worldconfig temporalStability',
      %w[wc-set caveIns true] => 'worldconfig caveIns true',
      %w[wc-set daysPerMonth 56] => 'worldconfig daysPerMonth 56',
      %w[genbackup] => 'genbackup',
      %w[genbackup before-prune] => 'genbackup before-prune'
    }
    reject = [
      [], %w[list evil], %w[info bogus], %w[time x], %w[mods x], %w[autosavenow x],
      %w[wc], ['wc', ''], %w[wc a b], ['wc', 'temporalStability false'], %w[wc bad;rm],
      %w[wc-set], %w[wc-set caveIns], %w[wc-set caveIns true x],
      ['wc-set', 'caveIns', 'true false'], %w[wc-set bad;rm true], %w[wc-set caveIns ev;il],
      ['genbackup', 'bad name'],
      %w[genbackup weird$name], %w[genbackup a b], %w[stop x], %w[db prune], %w[wgen regen],
      %w[ban someone], %w[kick someone], %w[role x admin], %w[worldconfig x true]
    ]
    parse = [
      ['worldconfig temporalStability currently has value: True', true, true],
      ['worldconfig allowLandClaiming currently has value: False', false, false],
      ['worldconfig microblockChiseling currently has value: all', 'all', 'all'],
      ['worldconfig deathPunishment currently has value: keep all', 'drop', 'keep all'],
      ['worldconfig saturation currently has value: 0.5', 0.5, 0.5],
      ['worldconfig daysPerMonth currently has value: 9', 0, 9],
      ['unexpected reply with no value marker', 'x', nil],
      ['unexpected reply with no value marker', true, nil]
    ]
    run_cases(ok, reject, parse)
  end

  def run_cases(ok, reject, parse)
    failures = 0
    ok.each do |argv, expected|
      got = resolve(argv)
      next if got == expected

      warn "FAIL resolve(#{argv.inspect}) = #{got.inspect}; expected #{expected.inspect}"
      failures += 1
    rescue StandardError => e
      warn "FAIL resolve(#{argv.inspect}) raised #{e.inspect}; expected #{expected.inspect}"
      failures += 1
    end
    reject.each do |argv|
      got = resolve(argv)
      warn "FAIL resolve(#{argv.inspect}) = #{got.inspect}; expected Reject"
      failures += 1
    rescue Reject
      nil
    rescue StandardError => e
      warn "FAIL resolve(#{argv.inspect}) raised #{e.inspect}; expected Reject"
      failures += 1
    end
    parse.each do |reply, canon_val, expected|
      got = parse_wc_value(reply, canon_val)
      next if got == expected && got.instance_of?(expected.class)

      warn "FAIL parse_wc_value(#{reply.inspect}, #{canon_val.inspect}) = #{got.inspect}"
      failures += 1
    end
    if failures.positive?
      warn "#{failures} failure(s)"
      return 1
    end
    puts "all #{ok.size + reject.size + parse.size} dispatcher tests passed"
    0
  end
end

if __FILE__ == $PROGRAM_NAME
  case ARGV[0]
  when '--selftest' then exit Rcon.selftest
  when 'wc-dump' then exit Rcon.wc_dump(ARGV[1])
  else
    begin
      command = Rcon.resolve(ARGV)
    rescue Rcon::Reject => e
      warn "rcon.rb: #{e.message}"
      exit e.code
    end
    begin
      print Rcon.send_cmd(command)
    rescue IOError, Errno::ECONNRESET
      # /stop tears the socket down before the end-marker — expected, not a failure.
      raise unless command == 'stop'

      puts 'stop sent; server shutting down (Host Havoc should auto-restart)'
    end
  end
end
