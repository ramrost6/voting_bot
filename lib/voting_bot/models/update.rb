# frozen_string_literal: true

module VotingBot
  module Models
    class Update
      attr_reader :update_id, :chat_id, :user_id, :text, :username, :first_name

      def initialize(update_id:, chat_id:, user_id:, text:, username:, first_name:)
        @update_id = update_id
        @chat_id = chat_id
        @user_id = user_id
        @text = text.to_s
        @username = username
        @first_name = first_name
      end

      def self.from_telegram(payload)
        message = payload["message"]
        return nil unless message

        text = message["text"].to_s
        return nil if text.strip.empty?

        new(
          update_id: payload.fetch("update_id"),
          chat_id: message.dig("chat", "id"),
          user_id: message.dig("from", "id"),
          text: text,
          username: message.dig("from", "username"),
          first_name: message.dig("from", "first_name")
        )
      end

      def command?
        body.start_with?("/")
      end

      def command_name
        return nil unless command?

        token = body.split(/\s+/, 2).first
        token.delete_prefix("/").split("@", 2).first
      end

      def arguments
        return "" unless command?

        parts = body.split(/\s+/, 2)
        parts[1].to_s.strip
      end

      def body
        @body ||= @text.strip
      end

      def display_name
        username_text = @username.to_s.strip
        return "@#{username_text}" unless username_text.empty?

        first_name_text = @first_name.to_s.strip
        return first_name_text unless first_name_text.empty?

        @user_id.to_s
      end
    end
  end
end
