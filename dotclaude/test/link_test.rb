#!/usr/bin/env ruby
# frozen_string_literal: true

# Exercises the shared link.rb against a throwaway CLAUDE_HOME. Stdlib only.
#   ruby test/link_test.rb

require 'minitest/autorun'
require 'json'
require 'tmpdir'

class SharedLinkTest < Minitest::Test
  SRC = File.expand_path('..', __dir__)

  def link(home)
    system({ 'CLAUDE_HOME' => home }, File.join(SRC, 'link.rb'),
           out: File::NULL, err: File::NULL)
  end

  def with_home
    Dir.mktmpdir do |home|
      link(home)
      yield home
    end
  end

  def test_skills_is_a_real_dir_not_a_symlink
    with_home do |home|
      assert File.directory?(File.join(home, 'skills'))
      refute File.symlink?(File.join(home, 'skills'))
    end
  end

  def test_singletons_and_content_link
    with_home do |home|
      assert File.exist?(File.join(home, 'settings.json'))
      assert File.exist?(File.join(home, 'CLAUDE.md'))
      assert File.symlink?(File.join(home, 'skills', 'write-gooder'))
      assert File.symlink?(File.join(home, 'skills', 'double-check'))
      assert File.symlink?(File.join(home, 'agents', 'security-expert.md'))
      assert File.symlink?(File.join(home, 'rules', 'testing.md'))
      assert File.symlink?(File.join(home, 'hooks', 'git-town-steer.sh'))
    end
  end

  def test_shared_settings_excludes_work_only_keys
    settings = JSON.parse(File.read(File.join(SRC, 'settings.json')))
    refute settings.key?('apiKeyHelper'), 'NR credential helper must stay work-only'
    refute settings.dig('env', 'ANTHROPIC_BASE_URL'), 'NR gateway URL must stay work-only'
    refute settings.key?('statusLine'), 'work statusLine must stay work-only'
    refute settings.key?('model'), 'home picks its own model'
    assert settings.dig('env', 'CLAUDE_CODE_SCROLL_SPEED'), 'general env must be preserved'
    assert settings.dig('permissions', 'deny').length >= 50, 'safety deny-list must be present'
  end

  def test_engineering_standards_stays_work_only
    with_home do |home|
      refute File.exist?(File.join(home, 'rules', 'engineering-standards.md'))
    end
  end

  def test_no_nr_account_ids_in_public_content
    ids = /\b(?:1037563|313870|11044818|3172319|332029)\b/
    hits = Dir.glob(File.join(SRC, '{skills,rules,agents}', '**', '*'))
              .select { |f| File.file?(f) && File.read(f).match?(ids) }
    assert_empty hits, "NR account IDs must not appear in public content: #{hits}"
  end
end
