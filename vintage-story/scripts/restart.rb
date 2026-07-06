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
#   restart.rb --force   # skip the online-player check
require_relative 'lib'
require_relative 'rcon'

module Restart
  LOG = 'Logs/server-main.log'
  READY = 'Dedicated Server now running on Port'
  ERROR_RE = /\[Error\]|Exception|cannot be resolved|NullReference|Fatal/
  POLL = 10 # seconds between log checks
  # ~15 minutes of waiting for boot — Host Havoc's own stop->relaunch latency,
  # not game boot time, has been the bottleneck in observed false-negatives
  # (the game itself boots in ~15-20s once launched)
  TRIES = 90
  WATCH = 60 # seconds to keep scanning for late errors after the port opens

  module_function

  def log_path
    File.join(VS.remote_base, LOG)
  end

  # "List of online Players" with no further lines means nobody's connected.
  def online_players
    Rcon.send_cmd('list clients').lines.map(&:strip).grep(/\APlaying /)
  end

  # New log content since `offset` bytes. Returns whole file if it rotated
  # (shrank below offset), or nil if SFTP is momentarily unavailable.
  def tail_since(offset)
    data = VS.sftp { |sftp| sftp.download!(log_path) }
    data.bytesize < offset ? data : (data.byteslice(offset..) || '')
  rescue StandardError
    nil
  end

  def baseline
    VS.sftp { |sftp| sftp.stat!(log_path).size }
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
    return 1 unless booted?(start)

    scan_late_errors(start)
  end

  def stop
    Rcon.send_cmd('stop')
  rescue IOError, Errno::ECONNRESET
    nil # /stop tears down the socket before replying — expected
  end

  def booted?(start)
    TRIES.times do |i|
      sleep POLL
      data = tail_since(start)
      if data&.include?(READY)
        puts "booted after ~#{(i + 1) * POLL}s — game port open"
        return true
      end
      status = data.nil? ? 'SFTP fetch failed' : "#{data.bytesize}B fetched, no ready line yet"
      puts "  ...waiting (#{(i + 1) * POLL}s) — #{status}"
    end
    warn "restart: no '#{READY}' after ~#{TRIES * POLL}s — check the Host Havoc panel"
    false
  end

  def scan_late_errors(start)
    puts "watching ~#{WATCH}s for late errors..."
    sleep WATCH
    boot = tail_since(start).to_s
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
end

exit Restart.run(force: ARGV.include?('--force')) if __FILE__ == $PROGRAM_NAME
