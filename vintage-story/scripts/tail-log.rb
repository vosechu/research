#!/usr/bin/env ruby
# frozen_string_literal: true

# Polls a server log via SFTP and prints only new bytes. Strictly read-only.
# Usage: tail-log.rb [poll_seconds=15] [log_name=server-main.log]
require 'tmpdir'
require_relative 'lib'

interval = (ARGV[0] || '15').to_i
logname = ARGV[1] || 'server-main.log'
cur = File.join(Dir.tmpdir, "vs_tail_#{logname}.cur")
remote = File.join(VS.remote_base, 'Logs', logname)
prev = File.exist?(cur) ? File.size(cur) : 0

loop do
  begin
    VS.sftp { |sftp| sftp.download!(remote, cur) }
  rescue StandardError
    # transient connection/file errors: skip this poll and retry
  end
  size = File.exist?(cur) ? File.size(cur) : 0
  if size > prev
    File.open(cur) do |file|
      file.seek(prev)
      $stdout.write(file.read(size - prev))
      $stdout.flush
    end
  end
  prev = size # also resets when the log rotates/shrinks (size < prev)
  sleep interval
end
