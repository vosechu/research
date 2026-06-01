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

  # Yields an authenticated Net::SFTP session. net-sftp does password auth
  # natively, which is why no expect/sshpass is needed.
  def sftp(&)
    require 'net/sftp'
    Net::SFTP.start(
      fetch('SFTP_HOST'),
      fetch('SFTP_USER'),
      password: fetch('SFTP_PASS'),
      port: Integer(env['SFTP_PORT'] || '22'),
      auth_methods: %w[password keyboard-interactive],
      verify_host_key: :accept_new,
      non_interactive: true, &
    )
  end
end
