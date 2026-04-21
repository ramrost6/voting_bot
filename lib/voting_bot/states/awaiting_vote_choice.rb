# frozen_string_literal: true

module VotingBot
  module States
    class AwaitingVoteChoice < Base
      private

      def handle
        if update.command? && update.command_name == "cancel"
          session.reset!
          return reply("Голосование отменено.")
        end

        poll_id = session.data["poll_id"]
        poll = store.find_poll(poll_id)
        raise ArgumentError, "Опрос не найден." unless poll

        if poll.closed?
          session.reset!
          return reply("Опрос ##{poll.id} уже закрыт.\n\n#{results_text(poll)}")
        end

        return add_option(poll) if update.body.to_s.strip.start_with?("+")

        already_voted = poll.selected_options_for(update.user_id).any?
        poll.vote(user_id: update.user_id, option_input: update.body, display_name: update.display_name)
        store.update_poll(poll)
        session.reset!

        confirmation = already_voted ? "Ответ обновлён в опросе ##{poll.id}." : "Голос принят в опросе ##{poll.id}."
        correctness = correctness_feedback(poll)

        reply(
          [
            confirmation,
            correctness,
            "Текущие результаты:",
            results_text(poll)
          ].compact.join("\n")
        )
      end

      def add_option(poll)
        option_text = update.body.to_s.strip.delete_prefix("+").strip
        raise ArgumentError, "После знака + укажите текст нового варианта." if option_text.empty?

        poll.add_option(option_text)
        store.update_poll(poll)

        reply(
          [
            "Новый вариант добавлен: #{option_text}",
            "Теперь отправьте свой выбор:",
            format_options(poll)
          ].join("\n")
        )
      end

      def correctness_feedback(poll)
        verdict = poll.correct_selection_for?(update.user_id)
        return nil if verdict.nil?

        verdict ? "Ваш выбор совпадает с правильным ответом." : "Ваш выбор не совпадает с правильным ответом."
      end
    end
  end
end
