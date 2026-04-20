# frozen_string_literal: true

module VotingBot
  module States
    class Idle < Base
      private

      def handle
        return reply(default_text) unless update.command?

        case update.command_name
        when "start"
          reply("Привет, #{update.display_name}! Я помогу создать опрос через VotingWizard.\n\n#{help_text}")
        when "help"
          reply(help_text)
        when "new_poll"
          session.transition_to("awaiting_question")
          reply("Пришлите текст вопроса для нового опроса.")
        when "polls"
          reply(list_text(store.list_polls))
        when "my_polls"
          reply(list_text(store.list_polls_by_creator(update.user_id)))
        when "results"
          poll = store.find_poll(parse_poll_id(update.arguments))
          raise ArgumentError, "Опрос не найден." unless poll

          reply(results_text(poll))
        when "vote"
          poll = store.find_poll(parse_poll_id(update.arguments))
          raise ArgumentError, "Опрос не найден." unless poll

          session.transition_to("awaiting_vote_choice", {"poll_id" => poll.id})
          reply(
            [
              "Вы выбрали опрос ##{poll.id}: #{poll.question}",
              "Отправьте номер варианта или его текст:",
              format_options(poll)
            ].join("\n")
          )
        when "cancel"
          reply("Сейчас нет активного сценария для отмены.")
        else
          reply(default_text)
        end
      end

      def default_text
        "Я работаю с командами.\n\n#{help_text}"
      end

      def format_options(poll)
        poll.options.each_with_index.map { |option, index| "#{index + 1}. #{option}" }.join("\n")
      end
    end
  end
end
