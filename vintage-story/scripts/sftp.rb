#!/usr/bin/env ruby
# frozen_string_literal: true

# Verb CLI over net-sftp. Remote paths are relative to REMOTE_BASE unless they
# start with "/". One verb == one net-sftp call; nothing else can be expressed.
#
# Usage:
#   sftp.rb ls [remote]
#   sftp.rb get <remote> <local>
#   sftp.rb put <local> <remote>
#   sftp.rb mput <local-glob> <remote-dir>
#   sftp.rb rm <remote>
#   sftp.rb rmdir <remote>
#   sftp.rb rename <remote-old> <remote-new>
#   sftp.rb mkdir <remote>
#
# put/mput/rm/rmdir/rename/mkdir write the live server and are blocked by the
# vs-guard hook in auto mode; chuck runs those himself with the `!` prefix.
require_relative 'lib'

module Sftp
  VERBS = %w[ls get put mput rm rmdir rename mkdir].freeze

  module_function

  def remote(path)
    path.start_with?('/') ? path : File.join(VS.remote_base, path)
  end

  def run(argv)
    verb, *rest = argv
    unless VERBS.include?(verb)
      warn "sftp.rb: unknown verb #{verb.inspect} (see header for usage)"
      return 2
    end
    VS.sftp { |sftp| public_send(verb, sftp, *rest) }
    0
  end

  def ls(sftp, path = '')
    sftp.dir.foreach(remote(path)) { |entry| puts entry.longname }
  end

  def get(sftp, src, dst)
    sftp.download!(remote(src), dst)
    puts "got #{src} -> #{dst}"
  end

  def put(sftp, src, dst)
    sftp.upload!(src, remote(dst))
    puts "put #{src} -> #{dst}"
  end

  def mput(sftp, glob, dst_dir)
    files = Dir.glob(glob)
    raise "no local files match #{glob.inspect}" if files.empty?

    files.each do |file|
      target = File.join(remote(dst_dir), File.basename(file))
      sftp.upload!(file, target)
      puts "put #{file} -> #{target}"
    end
  end

  def rm(sftp, path)
    sftp.remove!(remote(path))
    puts "removed #{path}"
  end

  def rmdir(sftp, path)
    sftp.rmdir!(remote(path))
    puts "removed dir #{path}"
  end

  def rename(sftp, old, new)
    sftp.rename!(remote(old), remote(new))
    puts "renamed #{old} -> #{new}"
  end

  def mkdir(sftp, path)
    sftp.mkdir!(remote(path))
    puts "made dir #{path}"
  end
end

exit Sftp.run(ARGV) if __FILE__ == $PROGRAM_NAME
