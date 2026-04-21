# frozen_string_literal: true

module VotingBot
  module States
    class AwaitingCorrectAnswers < Base
      private

      def handle
        if update.command?
          return cancel if update.command_name == "cancel"
          return skip if update.command_name == "skip"
        end

        settings = current_draft_settings
        settings["correct_answers"] = resolve_draft_option_choices(update.body)
        session.transition_to("awaiting_poll_settings", draft_payload("draft_settings" => settings))

        reply(
          [
            "Правильные варианты сохранены: #{settings['correct_answers'].join(', ')}",
            settings_menu_text(settings)
          ].join("\n\n")
        )
      end

      def cancel
        session.reset!
        reply("Создание опроса отменено.")
      end

      def skip
        settings = current_draft_settings
        settings["correct_answers"] = []
        session.transition_to("awaiting_poll_settings", draft_payload("draft_settings" => settings))

        reply(
          [
            "Режим правильных ответов выключен.",
            settings_menu_text(settings)
          ].join("\n\n")
        )
      end
    end
  end
end
