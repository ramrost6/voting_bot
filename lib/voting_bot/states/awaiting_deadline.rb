# frozen_string_literal: true

module VotingBot
  module States
    class AwaitingDeadline < Base
      private

      def handle
        if update.command?
          return cancel if update.command_name == "cancel"
          return skip if update.command_name == "skip"
        end

        settings = current_draft_settings
        settings["deadline_at"] = parse_deadline_input(update.body, reference_time: Time.now)
        session.transition_to("awaiting_poll_settings", draft_payload("draft_settings" => settings))

        reply(
          [
            "Дедлайн сохранён: #{format_deadline(settings['deadline_at'])}",
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
        settings["deadline_at"] = nil
        session.transition_to("awaiting_poll_settings", draft_payload("draft_settings" => settings))

        reply(
          [
            "Ограничение срока выключено.",
            settings_menu_text(settings)
          ].join("\n\n")
        )
      end
    end
  end
end
