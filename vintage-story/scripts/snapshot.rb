#!/usr/bin/env ruby
# frozen_string_literal: true

# Pulls a timestamped snapshot of live server state into snapshots/<UTC-ts>/.
#
# Two kinds of state:
#   - On-disk files (serverconfig, playerdata, ...) via SFTP. These are the
#     creation-time SEED for a world, not its live state — kept for reference.
#   - The LIVE worldconfig, read field-by-field over RCON (worldconfig.live.json),
#     because a world's WorldConfiguration lives in the savegame DB, not the file.
require 'fileutils'
require_relative 'lib'

# remote-subdir => files to pull from it
FILES = {
  '' => %w[serverconfig.json servermagicnumbers.json],
  'Playerdata' => %w[playerdata.json playersbanned.json playerswhitelisted.json playergroups.json],
  'Logs' => %w[server-main.log server-audit.log]
}.freeze

ts = Time.now.utc.strftime('%Y-%m-%dT%H%MZ')
out = File.join(VS::ROOT, 'snapshots', ts)
FileUtils.mkdir_p(out)
puts "snapshotting into #{out}"

puts '== on-disk files (SFTP) =='
VS.sftp do |sftp|
  FILES.each do |subdir, names|
    names.each do |name|
      remote = File.join(*[VS.remote_base, subdir, name].reject(&:empty?))
      sftp.download!(remote, File.join(out, name))
      puts "  got #{name}"
    rescue StandardError => e
      warn "  skip #{name}: #{e.message}"
    end
  end
end

puts '== live worldconfig (RCON) =='
rcon = File.join(__dir__, 'rcon.rb')
unless system(RbConfig.ruby, rcon, 'wc-dump', File.join(out, 'worldconfig.live.json'))
  puts '  (RCON unavailable — worldconfig.live.json skipped; on-disk files still captured)'
end

puts '---'
puts Dir.children(out).sort
