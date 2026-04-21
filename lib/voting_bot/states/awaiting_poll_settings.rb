# frozen_string_literal: true

module VotingBot
  module States
    class AwaitingPollSettings < Base
      private

      def handle
        if update.command?
          return cancel if update.command_name == "cancel"
          return finalize_poll if update.command_name == "done"
        end

        raw_choice = update.body.to_s.strip
        raise ArgumentError, "Отправьте номер настройки от 1 до 7, /done или /cancel." unless raw_choice.match?(/\A[1-7]\z/)

        case raw_choice.to_i
        when 1 then toggle_boolean_setting("show_voter_names", "Имена участников")
        when 2 then toggle_boolean_setting("multiple_answers", "Несколько ответов")
        when 3 then toggle_boolean_setting("allow_option_addition", "Добавление вариантов")
        when 4 then toggle_boolean_setting("allow_vote_change", "Изменение ответа")
        when 5 then toggle_boolean_setting("random_order", "Случайный порядок")
        when 6 then request_correct_answers
        when 7 then request_deadline
        end
      end

      def cancel
        session.reset!
        reply("Создание опроса отменено.")
      end

      def finalize_poll
        poll = store.create_poll(
          question: session.data.fetch("draft_question"),
          options: Array(session.data["draft_options"]),
          creator_id: update.user_id,
          settings: current_draft_settings
        )

        session.reset!

        lines = [
          "Опрос создан.",
          "ID: #{poll.id}",
          "Вопрос: #{poll.question}",
          "Команда для голосования: /vote #{poll.id}"
        ]
        lines.concat(poll_settings_lines(poll))

        reply(lines.join("\n"))
      end

      def toggle_boolean_setting(key, title)
        settings = current_draft_settings
        settings[key] = !settings[key]
        session.transition_to("awaiting_poll_settings", draft_payload("draft_settings" => settings))

        reply(
          [
            "#{title}: #{settings[key] ? 'включено' : 'выключено'}.",
            settings_menu_text(settings)
          ].join("\n\n")
        )
      end

      def request_correct_answers
        session.transition_to("awaiting_correct_answers", draft_payload)

        reply(
          [
            "Отправьте один или несколько правильных вариантов через запятую.",
            "Можно указывать номера или тексты вариантов.",
            current_correct_answers_line,
            "Отправьте /skip, чтобы выключить режим правильных ответов."
          ].compact.join("\n")
        )
      end

      def request_deadline
        session.transition_to("awaiting_deadline", draft_payload)

        reply(
          [
            "Отправьте дедлайн в формате YYYY-MM-DD HH:MM или числом минут от текущего момента.",
            current_deadline_line,
            "Отправьте /skip, чтобы убрать ограничение срока."
          ].compact.join("\n")
        )
      end

      def current_correct_answers_line
        correct_answers = current_draft_settings["correct_answers"]
        return nil if correct_answers.empty?

        "Сейчас отмечено: #{correct_answers.join(', ')}"
      end

      def current_deadline_line
        deadline = current_draft_settings["deadline_at"]
        return nil unless deadline

        "Сейчас установлен дедлайн: #{format_deadline(deadline)}"
      end
    end
  end
end
