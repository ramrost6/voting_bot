# frozen_string_literal: true

require "bundler/setup"
require "tmpdir"
require_relative "../lib/voting_bot"

class FakeTelegramClient
  attr_reader :messages

  def initialize
    @messages = []
  end

  def send_message(chat_id:, text:)
    @messages << {chat_id: chat_id, text: text}
  end
end

module SimpleAssertions
  def assert(condition, message = "Assertion failed")
    raise message unless condition
  end

  def assert_equal(expected, actual, message = nil)
    return if expected == actual

    raise(message || "Expected #{expected.inspect}, got #{actual.inspect}")
  end

  def refute_nil(value, message = "Expected value not to be nil")
    raise message if value.nil?
  end
end
