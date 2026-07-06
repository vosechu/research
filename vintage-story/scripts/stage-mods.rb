#!/usr/bin/env ruby
# frozen_string_literal: true

# Promote LOCAL_MODS (the live game client's Mods folder, managed by rustique)
# into STAGED_MODS — deploy.rb's actual source of truth. Decouples the deploy
# snapshot from the live client folder, so troubleshooting the client's Mods
# folder directly (e.g. clearing it to resolve a version mismatch) can't
# silently change what deploy.rb thinks should be live.
#
# Dry-run by default; pass --apply to actually write. Only mirrors *.zip files.
#
# Usage:
#   stage-mods.rb            # show the plan, write nothing
#   stage-mods.rb --apply    # copy new/changed, remove stale
require_relative 'lib'
require 'fileutils'

module StageMods
  module_function

  def zips_in(dir)
    Dir.glob(File.join(dir, '*.zip')).to_h { |p| [File.basename(p), p] }
  end

  def plan(source, dest)
    uploads = source.keys.reject { |n| dest[n] && File.size(dest[n]) == File.size(source[n]) }.sort
    stale = (dest.keys - source.keys).sort
    [uploads, stale]
  end

  def print_plan(source, dest, uploads, stale, apply)
    puts "local zips: #{source.size}   staged zips: #{dest.size}"
    puts "\nCOPY to staged (#{uploads.size}):"
    uploads.each { |n| puts "  + #{n}#{' (changed)' if dest.key?(n)}" }
    puts "\nREMOVE from staged (#{stale.size}):"
    stale.each { |n| puts "  - #{n}" }
    puts "\n(dry-run — pass --apply to execute)" unless apply
  end

  def execute(source_dir, dest_dir, uploads, stale)
    puts "\napplying..."
    uploads.each do |name|
      FileUtils.cp(File.join(source_dir, name), File.join(dest_dir, name))
      puts "  copied #{name}"
    end
    stale.each do |name|
      File.delete(File.join(dest_dir, name))
      puts "  removed #{name}"
    end
    puts 'done'
  end

  def run(apply)
    source_dir = VS.fetch('LOCAL_MODS')
    dest_dir = VS.fetch('STAGED_MODS')
    raise "missing local mods dir #{source_dir}" unless Dir.exist?(source_dir)

    FileUtils.mkdir_p(dest_dir)
    source = zips_in(source_dir)
    dest = zips_in(dest_dir)
    uploads, stale = plan(source, dest)

    print_plan(source, dest, uploads, stale, apply)
    execute(source_dir, dest_dir, uploads, stale) if apply
    0
  end
end

exit StageMods.run(ARGV.include?('--apply')) if __FILE__ == $PROGRAM_NAME
