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
# genbackup is deliberately NOT bundled: it runs async on the server and a stop
# fired mid-backup would truncate it. Take `rcon.rb genbackup <name>` before
# risky changes instead (the deploy flow already does). autosavenow IS included
# because it's synchronous and confirms a fresh save before the bounce.
#
# Usage:
#   restart.rb        # autosavenow -> stop -> wait for port -> scan for late errors
require_relative 'lib'
require_relative 'rcon'

module Restart
  LOG = 'Logs/server-main.log'
  READY = 'Dedicated Server now running on Port'
  ERROR_RE = /\[Error\]|Exception|cannot be resolved|NullReference|Fatal/
  POLL = 10  # seconds between log checks
  TRIES = 36 # ~6 minutes of waiting for boot
  WATCH = 60 # seconds to keep scanning for late errors after the port opens

  module_function

  def log_path
    File.join(VS.remote_base, LOG)
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

  def run
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
      puts "  ...waiting (#{(i + 1) * POLL}s)"
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

exit Restart.run if __FILE__ == $PROGRAM_NAME
