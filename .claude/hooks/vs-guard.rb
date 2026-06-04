#!/usr/bin/env ruby
# frozen_string_literal: true

# PreToolUse(Bash) guard for the Vintage Story workspace.
#
# Blocks RAW WRITES to the live server so they can never run ad-hoc in auto mode:
#   - sftp.rb put/mput/rm/rmdir/rename/mkdir  (live SFTP writes)
#   - rcon.rb wc-set                          (the RCON worldconfig write path)
#
# Sanctioned write paths that DO pass (chuck opted in for this private server):
#   - deploy.rb [--apply]   the safe mod-mirror wrapper (dry-run default, backs
#                           up, protects engine dlls, prints plan before writing)
#   - rcon.rb stop          server shutdown -> Host Havoc auto-restart
# Reads, pulls, snapshots, log tailing, and read-only rcon.rb subcommands also pass.
#
# The deliberate gap: raw one-off SFTP writes and wc-set still require the `!`
# prefix (not a Claude tool call, so they never reach this hook). The policy is
# "deploy through the reviewed wrapper, not by hand."
#
# Self-test (no stdin):  .claude/hooks/vs-guard.rb --selftest
require 'json'

module Guard
  WRITE_VERBS = %w[put mput rm rmdir rename mkdir].freeze

  module_function

  # True if cmd is a live-server write (BLOCK).
  def live_write?(cmd)
    return false if cmd.nil? || cmd.empty?
    return true if cmd.include?('rcon.rb') && cmd.match?(/\bwc-set\b/)
    return WRITE_VERBS.any? { |verb| cmd.match?(/\b#{verb}\b/) } if cmd.include?('sftp.rb')

    false
  end

  def selftest
    block = [
      'sftp.rb put configs/playerdata.json Playerdata/playerdata.json',
      'vintage-story/scripts/sftp.rb mput /tmp/vs_local_mods/*.zip Mods',
      'sftp.rb rm Mods/oldmod.zip',
      'sftp.rb rename a.json b.json',
      'sftp.rb mkdir Backups',
      'ruby scripts/rcon.rb wc-set caveIns true',
      'vintage-story/scripts/rcon.rb wc-set daysPerMonth 56',
      '{"tool_input":{"command":"scripts/sftp.rb put a b"}}' # raw-payload backstop
    ]
    allow = [
      'sftp.rb ls Mods',
      'sftp.rb get serverconfig.json ./serverconfig.json',
      'vintage-story/scripts/snapshot.rb',
      'vintage-story/scripts/tail-log.rb',
      'ruby scripts/rcon.rb list',
      'scripts/rcon.rb wc creatureStrength',
      'scripts/rcon.rb wc-dump snapshots/x/worldconfig.live.json',
      'vintage-story/scripts/deploy.rb',
      'vintage-story/scripts/deploy.rb --apply',
      'vintage-story/scripts/rcon.rb stop',
      'vintage-story/scripts/restart.rb',
      'git status',
      'echo "put this in the output"',
      '{"tool_input":{"command":"scripts/sftp.rb ls Mods"}}' # raw payload, read-only
    ]
    failures = 0
    block.each do |c|
      unless live_write?(c)
        (warn "FAIL expected BLOCK: #{c}"
         failures += 1)
      end
    end
    allow.each do |c|
      if live_write?(c)
        (warn "FAIL expected ALLOW: #{c}"
         failures += 1)
      end
    end
    if failures.positive?
      warn "#{failures} failure(s)"
      return 1
    end
    puts "all #{block.size + allow.size} guard tests passed"
    0
  end
end

exit Guard.selftest if ARGV[0] == '--selftest'

input = $stdin.read
cmd = begin
  JSON.parse(input).dig('tool_input', 'command')
rescue StandardError
  nil # parse failed — the raw-input scan below still runs (fail CLOSED)
end

if Guard.live_write?(cmd) || Guard.live_write?(input)
  warn <<~MSG
    BLOCKED by vs-guard: this writes to the LIVE Vintage Story server.
    Live writes (config pushes, mod deploys, wc-set) require chuck's explicit
    approval and cannot run in auto mode. Surface the exact command and have chuck
    run it himself with the `!` prefix (that bypasses this hook).
  MSG
  exit 2
end
exit 0
