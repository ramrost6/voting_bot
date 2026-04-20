# frozen_string_literal: true

module VotingBot
  class Responder
    def initialize(client:, chat_id:)
      @client = client
      @chat_id = chat_id
    end

    def reply(text)
      @client.send_message(chat_id: @chat_id, text: text)
    end
  end
end
