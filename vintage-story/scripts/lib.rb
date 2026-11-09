# frozen_string_literal: true

# Shared helpers for the Vintage Story scripts. `require_relative "lib"`.
# Loads .env once and exposes config + an authenticated SFTP session.
module VS
  ROOT = File.expand_path('..', __dir__) # scripts/ -> workspace root
  ENV_FILE = File.join(ROOT, '.env')

  module_function

  def env
    @env ||= load_env
  end

  def load_env
    raise "missing #{ENV_FILE}" unless File.exist?(ENV_FILE)

    File.readlines(ENV_FILE).each_with_object({}) do |line, acc|
      line = line.strip
      next if line.empty? || line.start_with?('#') || !line.include?('=')

      key, value = line.split('=', 2)
      acc[key.strip] = value.strip.gsub(/\A['"]|['"]\z/, '')
    end
  end

  def fetch(key)
    env[key] || ENV[key] || raise("missing #{key} in #{ENV_FILE} or environment")
  end

  def remote_base
    fetch('REMOTE_BASE')
  end

  # Yields an authenticated Net::SFTP session and returns THE BLOCK'S value.
  # net-sftp does password auth natively, which is why no expect/sshpass is needed.
  #
  # AI-DEV: The explicit `result` capture is load-bearing. `Net::SFTP.start` with a
  # block returns the *session*, not the block's value, so `VS.sftp { ... }` used to
  # hand back nil. Callers that only need side effects never noticed, but any caller
  # reading the return value silently got nil — which is what made restart.rb report
  # "SFTP fetch failed" for 15 minutes straight against a perfectly healthy server
  # (root-caused 2026-08-10). Do NOT "simplify" this back to block forwarding.
  def sftp
    require 'net/sftp'
    result = nil
    Net::SFTP.start(
      fetch('SFTP_HOST'),
      fetch('SFTP_USER'),
      password: fetch('SFTP_PASS'),
      port: Integer(env['SFTP_PORT'] || '22'),
      auth_methods: %w[password keyboard-interactive],
      verify_host_key: :accept_new,
      non_interactive: true
    ) { |session| result = yield(session) }
    result
  end
end
