# frozen_string_literal: true

module VotingBot
  module States
    class AwaitingOptions < Base
      private

      def handle
        if update.command?
          return cancel if update.command_name == "cancel"
          return proceed_to_settings if update.command_name == "done"
        end

        question = session.data.fetch("draft_question")
        options = Array(session.data["draft_options"])
        option_text = update.body

        preview_poll = VotingWizard::Poll.new(question)
        options.each { |option| preview_poll.add_option(option) }
        preview_poll.add_option(option_text)

        options << option_text
        session.data["draft_options"] = options

        reply(
          [
            "Вариант добавлен: #{option_text}",
            "Сейчас вариантов: #{options.size}",
            current_options_text(options),
            "Отправьте ещё вариант или /done для перехода к настройкам."
          ].join("\n")
        )
      end

      def cancel
        session.reset!
        reply("Создание опроса отменено.")
      end

      def proceed_to_settings
        options = Array(session.data["draft_options"])
        raise ArgumentError, "Нужно минимум 2 варианта ответа." if options.size < 2

        session.transition_to("awaiting_poll_settings", draft_payload)

        reply(
          [
            "Варианты сохранены. Теперь можно настроить опрос перед публикацией.",
            settings_menu_text
          ].join("\n\n")
        )
      end

      def current_options_text(options)
        lines = ["Текущие варианты:"]
        options.each_with_index do |option, index|
          lines << "#{index + 1}. #{option}"
        end
        lines.join("\n")
      end
    end
  end
end
