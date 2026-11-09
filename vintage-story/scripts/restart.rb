#!/usr/bin/env ruby
# frozen_string_literal: true

# Safe restart: flush a save, stop the server, wait for Host Havoc to bring it
# back, then scan the fresh boot output for errors.
#
# Readiness is keyed on the LOG line that the game port is open, NOT on RCON.
# RCON answers early (its mod loads before the world is ready), so "RCON responds"
# is a false ready signal. And errors frequently surface AFTER the port opens
# (chunk gen, mod init, first join), so we keep scanning for a grace window.
#
# Won't bounce a live session: aborts if any player is connected unless --force
# is given (a restart disconnects everyone, and chuck's standing preference for
# this private server is to wait for an empty server or get his explicit OK).
#
# genbackup is deliberately NOT bundled: it runs async on the server and a stop
# fired mid-backup would truncate it. Take `rcon.rb genbackup <name>` before
# risky changes instead (the deploy flow already does). autosavenow IS included
# because it's synchronous and confirms a fresh save before the bounce.
#
# Usage:
#   restart.rb          # abort if anyone's connected; else autosavenow -> stop -> wait -> scan
#   restart.rb --force  # skip the online-player check
#   restart.rb --selftest # run the in-file tests for the pure helpers
require_relative 'lib'
require_relative 'rcon'

# Backgrounded runs are block-buffered without this, so the task output file
# reads EMPTY for the entire run — indistinguishable from hung (2026-08-08).
$stdout.sync = true

module Restart
  LOG = 'Logs/server-main.log'
  READY = 'Dedicated Server now running on Port'
  ERROR_RE = /\[Error\]|Exception|cannot be resolved|NullReference|Fatal/
  POLL = 10 # seconds between log checks
  # ~15 minutes of waiting for boot — Host Havoc's own stop->relaunch latency,
  # not game boot time, has been the bottleneck in observed false-negatives
  # (the game itself boots in ~15-20s once launched)
  TRIES = 90
  WATCH = 20 # seconds to keep scanning for late errors after the port opens
  # Confirming the stop landed. The server is down for ~40s minimum (HH relaunch
  # plus a ~35s boot), so a 5s poll across 90s has ample room to catch it.
  STOP_POLL = 5
  STOP_TRIES = 18

  # data is the new log bytes, or nil when the fetch failed; error carries WHY.
  # Keeping the exception is the point: a bare `rescue => nil` turned 90 identical
  # failures into 90 identical useless lines (2026-08-08) with no way to tell a
  # throttled connection from a timeout from bad credentials.
  FetchResult = Struct.new(:data, :error)

  module_function

  def log_path
    File.join(VS.remote_base, LOG)
  end

  # "List of online Players" with no further lines means nobody's connected.
  def online_players
    Rcon.send_cmd('list clients').lines.map(&:strip).grep(/\APlaying /)
  end

  # Pure: the slice of `raw` after `offset` bytes. A file that shrank below the
  # offset has rotated, so the whole thing is new content.
  def slice_since(raw, offset)
    return raw if raw.bytesize < offset

    raw.byteslice(offset..) || ''
  end

  def tail_since(offset)
    raw = VS.sftp { |sftp| sftp.download!(log_path) }
    FetchResult.new(slice_since(raw, offset), nil)
  rescue StandardError => e
    FetchResult.new(nil, e)
  end

  # Pure: the per-poll progress line.
  def fetch_status(res)
    return "#{res.data.bytesize}B fetched, no ready line yet" unless res.error

    "SFTP fetch failed — #{res.error.class}: #{res.error.message}"
  end

  def baseline
    VS.sftp { |sftp| sftp.stat!(log_path).size }
  end

  def rcon_alive?
    Rcon.send_cmd('list clients')
    true
  rescue StandardError
    false
  end

  # The log shrinking below the pre-stop baseline means VS archived it and
  # started a fresh one — proof the process actually went down.
  def log_rotated?(start)
    baseline < start
  rescue StandardError
    false
  end

  # Verified 2026-08-10: a restart whose /stop silently did nothing still burned
  # the full 15-minute boot wait and then reported failure, on a server that had
  # never gone down. Fail fast and loudly instead.
  def stop_landed?(start)
    STOP_TRIES.times do |i|
      sleep STOP_POLL
      if log_rotated?(start)
        puts "stop confirmed after ~#{(i + 1) * STOP_POLL}s — log rotated"
        return true
      end
      unless rcon_alive?
        puts "stop confirmed after ~#{(i + 1) * STOP_POLL}s — RCON down"
        return true
      end
    end
    false
  end

  def run(force: false)
    unless force
      online = online_players
      unless online.empty?
        warn "restart: aborting, #{online.size} player(s) connected (pass --force to override):"
        online.each { |l| warn "  #{l}" }
        return 1
      end
    end

    start = baseline
    puts "flush + stop (log baseline #{start}B)"
    Rcon.send_cmd('autosavenow')
    stop

    unless stop_landed?(start)
      warn "restart: /stop had no effect after ~#{STOP_TRIES * STOP_POLL}s " \
           '(server still answering RCON, log never rotated) — nothing was restarted'
      return 1
    end

    return 1 unless booted?(start)

    scan_late_errors(start)
  end

  def stop
    Rcon.send_cmd('stop')
  rescue IOError, Errno::ECONNRESET
    nil # /stop tears down the socket before replying — expected
  end

  def booted?(start)
    last_error = nil
    TRIES.times do |i|
      sleep POLL
      res = tail_since(start)
      if res.data&.include?(READY)
        puts "booted after ~#{(i + 1) * POLL}s — game port open"
        return true
      end
      last_error = res.error
      puts "  ...waiting (#{(i + 1) * POLL}s) — #{fetch_status(res)}"
    end
    warn "restart: no '#{READY}' after ~#{TRIES * POLL}s — check the Host Havoc panel"
    if last_error
      warn 'restart: every fetch failed; last error was ' \
           "#{last_error.class}: #{last_error.message}"
    end
    false
  end

  def scan_late_errors(start)
    puts "watching ~#{WATCH}s for late errors..."
    sleep WATCH
    boot = tail_since(start).data.to_s
    post = boot[/#{Regexp.escape(READY)}.*/m] || boot
    errs = post.lines.grep(ERROR_RE)
    if errs.empty?
      puts 'clean: no [Error]/Exception after the port opened'
      return 0
    end
    warn "#{errs.size} post-boot error line(s):"
    errs.last(20).each { |l| warn "  #{l.chomp}" }
    1
  end

  # --- In-file tests ----------------------------------------------------------

  def selftest
    # AI-DEV: AI **MUST NOT** weaken or delete these cases. They were confirmed by
    # mutation (disabling the rotation branch fails 2; dropping the exception detail
    # from fetch_status fails 1). If one fails, the production code broke, not the test.
    failures = 0
    failures += check('slice_since offset 0 returns everything', slice_since('abcdef', 0), 'abcdef')
    failures += check('slice_since mid-file returns the tail', slice_since('abcdef', 4), 'ef')
    failures += check('slice_since at EOF returns empty', slice_since('abcdef', 6), '')
    failures += check('slice_since with an offset past EOF treats it as a rotation',
                      slice_since('abcdef', 7), 'abcdef')
    failures += check('slice_since on a rotated (shrunk) log returns the whole file',
                      slice_since('abc', 900), 'abc')

    ok = FetchResult.new('hello', nil)
    failures += check('fetch_status reports byte count on success',
                      fetch_status(ok), '5B fetched, no ready line yet')
    boom = FetchResult.new(nil, Errno::ECONNREFUSED.new('port 22'))
    surfaced = fetch_status(boom).start_with?('SFTP fetch failed — Errno::ECONNREFUSED:')
    failures += check('fetch_status surfaces the exception class and message', surfaced, true)

    if failures.zero?
      puts 'restart.rb selftest: all cases passed'
      0
    else
      warn "restart.rb selftest: #{failures} failure(s)"
      1
    end
  end

  def check(label, got, expected)
    return 0 if got == expected

    warn "FAIL #{label}: got #{got.inspect}, expected #{expected.inspect}"
    1
  end
end

if __FILE__ == $PROGRAM_NAME
  case ARGV.first
  when '--selftest' then exit Restart.selftest
  else exit Restart.run(force: ARGV.include?('--force'))
  end
end
