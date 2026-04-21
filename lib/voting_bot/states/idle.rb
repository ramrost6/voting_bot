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
          return reply("Опрос ##{poll.id} уже закрыт.\n\n#{results_text(poll)}") if poll.closed?

          session.transition_to("awaiting_vote_choice", {"poll_id" => poll.id})

          lines = [
            "Вы выбрали опрос ##{poll.id}: #{poll.question}",
            vote_prompt_text(poll),
            format_options(poll)
          ]
          lines << "Повторная отправка ответа заменит предыдущий выбор." if poll.allow_vote_change?
          lines << "Чтобы предложить новый вариант, отправьте сообщение в формате +Новый вариант." if poll.allow_option_addition?
          reply(lines.join("\n"))
        when "cancel"
          reply("Сейчас нет активного сценария для отмены.")
        else
          reply(default_text)
        end
      end

      def default_text
        "Я работаю с командами.\n\n#{help_text}"
      end

      def vote_prompt_text(poll)
        return "Отправьте номера или тексты вариантов через запятую:" if poll.multiple_answers?

        "Отправьте номер варианта или его текст:"
      end
    end
  end
end
