# frozen_string_literal: true

module VotingBot
  class Config
    DEFAULT_STORAGE_PATH = File.expand_path("../../db/bot_state.json", __dir__)

    attr_reader :token, :storage_path, :polling_timeout

    def initialize(
      token: ENV["TELEGRAM_BOT_TOKEN"],
      storage_path: ENV["BOT_STORAGE_PATH"] || DEFAULT_STORAGE_PATH,
      polling_timeout: ENV.fetch("TELEGRAM_POLL_TIMEOUT", "20")
    )
      raise ArgumentError, "TELEGRAM_BOT_TOKEN is required" if token.to_s.strip.empty?

      @token = token
      @storage_path = storage_path
      @polling_timeout = Integer(polling_timeout, 10)
    end
  end
end
