# frozen_string_literal: true

module VotingBot
  module States
    class AwaitingQuestion < Base
      private

      def handle
        if update.command? && update.command_name == "cancel"
          session.reset!
          return reply("Создание опроса отменено.")
        end

        question = update.body
        raise ArgumentError, "Вопрос не должен быть пустым." if question.empty?

        session.transition_to(
          "awaiting_options",
          {
            "draft_question" => question,
            "draft_options" => [],
            "draft_settings" => Models::PollRecord::DEFAULT_SETTINGS.each_with_object({}) do |(key, value), memo|
              memo[key] = value.is_a?(Array) ? value.dup : value
            end
          }
        )

        reply(
          [
            "Вопрос сохранён: #{question}",
            "Теперь отправляйте варианты ответа по одному сообщению.",
            "Когда вариантов будет достаточно, отправьте /done.",
            "Для отмены используйте /cancel."
          ].join("\n")
        )
      end
    end
  end
end
