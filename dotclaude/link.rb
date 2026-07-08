#!/usr/bin/env ruby
# frozen_string_literal: true

# Install Chuck's SHARED (general-purpose) user-level Claude config into
# ~/.claude by symlinking (or copying) each item from this repo. Idempotent
# and non-destructive: any pre-existing real file is backed up to
# ~/.claude/<name>.bak-<timestamp> before being replaced.
#
# This is the shared layer. At work, run the work repo's link.rb AFTER this
# one to layer NR-internal config and merge the singleton files on top.
#
# Usage:
#   ./link.rb            # symlink each item into ~/.claude (default)
#   ./link.rb --copy     # copy instead of symlink (no-symlink setups)
#   ./link.rb --dry-run  # print what would happen, change nothing
#
# Source of truth is THIS repo. Edit files here; symlinks make the edits live.

require 'fileutils'

# Links items from a source dir into a destination dir, per item, with backup.
class Linker
  def initialize(src:, dest:, mode: :symlink, dry: false)
    @src   = src
    @dest  = dest
    @mode  = mode
    @dry   = dry
    @stamp = Time.now.to_i
  end

  # Link a single relative path (file or dir) as-is.
  def link_one(rel)
    src = File.join(@src, rel)
    dst = File.join(@dest, rel)

    unless File.exist?(src) || File.symlink?(src)
      warn "SKIP (source missing): #{rel}"
      return
    end

    if File.symlink?(dst) && File.readlink(dst) == src
      puts "OK (already linked): #{rel}"
      return
    end

    act("mkdir -p #{File.dirname(dst)}") { FileUtils.mkdir_p(File.dirname(dst)) }

    if File.exist?(dst) || File.symlink?(dst)
      bak = "#{dst}.bak-#{@stamp}"
      puts "BACKUP: #{dst} -> #{bak}"
      act("mv #{dst} #{bak}") { FileUtils.mv(dst, bak) }
    end

    if @mode == :copy
      puts "COPY: #{rel}"
      act("cp -R #{src} #{dst}") { FileUtils.cp_r(src, dst) }
    else
      puts "LINK: #{rel} -> #{src}"
      act("ln -s #{src} #{dst}") { FileUtils.ln_s(src, dst) }
    end
  end

  # Link each child of a directory item individually (parent dir made real),
  # so a second layer can add its own children into the same dest dir.
  def link_children(dir)
    unless File.directory?(File.join(@src, dir))
      warn "SKIP (missing dir): #{dir}"
      return
    end
    act("mkdir -p #{File.join(@dest, dir)}") { FileUtils.mkdir_p(File.join(@dest, dir)) }
    Dir.children(File.join(@src, dir)).sort.each { |child| link_one(File.join(dir, child)) }
  end

  private

  # Run a filesystem action, or just print it under --dry-run.
  def act(desc)
    if @dry
      puts "DRY: #{desc}"
    else
      yield
    end
  end
end

# Items whose CHILDREN are linked individually (parent dir made real), so the
# work layer can add its own children into the same ~/.claude dirs.
DIR_ITEMS  = %w[agents skills rules hooks].freeze
# Single-file items linked as-is. CLAUDE.md is deliberately NOT here: it's
# merged by hand into ~/.claude/CLAUDE.md instead of symlinked, since that
# file is personal/live and this repo is public.
FILE_ITEMS = %w[settings.json].freeze

if __FILE__ == $PROGRAM_NAME
  src  = __dir__
  dest = ENV['CLAUDE_HOME'] || File.join(Dir.home, '.claude')
  mode = :symlink
  dry  = false

  ARGV.each do |arg|
    case arg
    when '--copy'    then mode = :copy
    when '--dry-run' then dry = true
    else
      warn "unknown arg: #{arg}"
      exit 2
    end
  end

  puts "Source : #{src}"
  puts "Dest   : #{dest}"
  mode_label = dry ? "#{mode} (dry-run)" : mode.to_s
  puts "Mode   : #{mode_label}"
  puts

  linker = Linker.new(src: src, dest: dest, mode: mode, dry: dry)
  FILE_ITEMS.each { |rel| linker.link_one(rel) }
  DIR_ITEMS.each  { |dir| linker.link_children(dir) }

  puts
  puts 'Done. Restart Claude Code (or start a new session) to pick up changes.'
end
