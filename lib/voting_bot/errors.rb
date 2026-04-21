# frozen_string_literal: true

module VotingBot
  class Error < StandardError; end
  class TelegramApiError < Error; end
  class PollClosedError < Error; end
  class OptionAdditionNotAllowedError < Error; end
end
