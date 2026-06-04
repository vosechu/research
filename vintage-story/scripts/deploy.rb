#!/usr/bin/env ruby
# frozen_string_literal: true

# Safe mod deploy: mirror the LOCAL mods folder up to the live server's Mods/.
# Local (LOCAL_MODS in .env) is the source of truth. Dry-run by default;
# pass --apply to actually write.
#
# Safety model (this wrapper IS the sanctioned write path; raw sftp.rb writes
# stay hook-blocked):
#   - Only manages *.zip mods. Engine assemblies (VS*.dll / VS*.pdb) and any
#     other non-zip file on the server are never deleted.
#   - Dry-run prints the exact upload + delete plan; --apply is required to write.
#   - RECONCILE DRIFT FIRST: anything on the server but not in LOCAL_MODS is
#     treated as stale and DELETED on --apply. If the server has zips you want to
#     keep, pull them into LOCAL_MODS before deploying (sftp.rb get), or they go.
#   - Take a backup first: `rcon.rb genbackup before-deploy` (not done here, so
#     deploy stays SFTP-only and side-effect-free until --apply).
#
# Usage:
#   deploy.rb            # show the plan, write nothing
#   deploy.rb --apply    # upload new/changed, delete stale
require_relative 'lib'

module Deploy
  MODS = 'Mods'
  PROTECT = /\AVS.*\.(?:dll|pdb)\z/i # engine assemblies — never delete

  module_function

  def local_zips
    Dir.glob(File.join(VS.fetch('LOCAL_MODS'), '*.zip')).to_h { |p| [File.basename(p), p] }
  end

  def remote_files(sftp)
    files = {}
    sftp.dir.foreach(File.join(VS.remote_base, MODS)) do |entry|
      next if entry.attributes.directory?

      files[entry.name] = entry.attributes.size
    end
    files
  end

  def plan(local, remote)
    uploads = local.keys.reject { |n| remote[n] == File.size(local[n]) }.sort
    stale = remote.keys.select { |n| n.end_with?('.zip') && !local.key?(n) }
    deletes = stale.grep_v(PROTECT).sort
    [uploads, deletes]
  end

  def run(apply)
    local = local_zips
    raise "no local zips in #{VS.fetch('LOCAL_MODS')}" if local.empty?

    VS.sftp do |sftp|
      remote = remote_files(sftp)
      uploads, deletes = plan(local, remote)
      print_plan(local, remote, uploads, deletes, apply)
      execute(sftp, local, uploads, deletes) if apply
    end
    0
  end

  def print_plan(local, remote, uploads, deletes, apply)
    server_zips = remote.count { |name, _| name.end_with?('.zip') }
    puts "local zips: #{local.size}   server zips: #{server_zips}"
    puts "\nUPLOAD (#{uploads.size}):"
    uploads.each { |n| puts "  + #{n}#{' (changed)' if remote.key?(n)}" }
    puts "\nDELETE from server (#{deletes.size}):"
    deletes.each { |n| puts "  - #{n}" }
    puts "\n(dry-run — pass --apply to execute)" unless apply
  end

  def execute(sftp, local, uploads, deletes)
    dest = File.join(VS.remote_base, MODS)
    puts "\napplying..."
    uploads.each do |name|
      sftp.upload!(local[name], File.join(dest, name))
      puts "  uploaded #{name}"
    end
    deletes.each do |name|
      sftp.remove!(File.join(dest, name))
      puts "  deleted #{name}"
    end
    puts 'done'
  end
end

exit Deploy.run(ARGV.include?('--apply')) if __FILE__ == $PROGRAM_NAME
