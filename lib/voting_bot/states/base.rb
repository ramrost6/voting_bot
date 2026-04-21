# frozen_string_literal: true

module VotingBot
  module States
    class Base
      SETTING_ITEMS = [
        ["show_voter_names", "Имена участников"],
        ["multiple_answers", "Несколько ответов"],
        ["allow_option_addition", "Добавление вариантов"],
        ["allow_vote_change", "Изменение ответа"],
        ["random_order", "Случайный порядок"],
        ["correct_answers", "Правильный ответ"],
        ["deadline_at", "Ограничение срока"]
      ].freeze

      def call(context)
        @context = context
        handle
      end

      private

      attr_reader :context

      def handle
        raise NotImplementedError, "#{self.class} must implement #handle"
      end

      def update
        context.update
      end

      def session
        context.session
      end

      def store
        context.store
      end

      def responder
        context.responder
      end

      def reply(text)
        responder.reply(text)
      end

      def help_text
        [
          "Доступные команды:",
          "/new_poll - создать новый опрос",
          "/polls - список всех опросов",
          "/my_polls - мои опросы",
          "/vote ID - проголосовать",
          "/results ID - показать результаты",
          "/cancel - отменить текущий сценарий"
        ].join("\n")
      end

      def list_text(polls)
        return "Опросов пока нет." if polls.empty?

        lines = ["Список опросов:"]
        polls.each do |poll|
          lines << "##{poll.id} - #{poll.question} (вариантов: #{poll.options.size}, участников: #{poll.total_votes}, статус: #{poll_status(poll)})"
        end
        lines.join("\n")
      end

      def results_text(poll)
        lines = [
          "Результаты опроса ##{poll.id}: #{poll.question}",
          "Статус: #{poll_status(poll)}"
        ]

        poll.display_options.each do |option|
          votes = poll.results.fetch(option, 0)
          label = poll.correct_answers.include?(option) ? "#{option} (правильный)" : option
          line = "- #{label}: #{votes} (#{format('%.2f', poll.percentage_for(option))}%)"

          if poll.show_voter_names?
            voter_names = poll.option_voter_names(option)
            line = "#{line} [#{voter_names.join(', ')}]" unless voter_names.empty?
          end

          lines << line
        end

        winner = poll.winner || "ничья или пока нет голосов"
        lines << "Всего участников: #{poll.total_votes}"
        lines << "Всего выборов: #{poll.total_selections}" if poll.multiple_answers?
        lines << "Правильные варианты: #{poll.correct_answers.join(', ')}" if poll.correct_answers?
        lines << "Лидер: #{winner}"
        lines.join("\n")
      end

      def parse_poll_id(argument)
        raw_value = argument.to_s.strip
        raise ArgumentError, "Укажите ID опроса, например /vote 1" unless raw_value.match?(/\A\d+\z/)

        raw_value.to_i
      end

      def format_options(poll)
        poll.display_options.each_with_index.map { |option, index| "#{index + 1}. #{option}" }.join("\n")
      end

      def poll_settings_lines(poll)
        enabled_features = []
        enabled_features << "имена участников" if poll.show_voter_names?
        enabled_features << "несколько ответов" if poll.multiple_answers?
        enabled_features << "добавление вариантов" if poll.allow_option_addition?
        enabled_features << "изменение ответа" if poll.allow_vote_change?
        enabled_features << "случайный порядок" if poll.random_order?
        enabled_features << "правильные ответы" if poll.correct_answers?
        enabled_features << "ограничение срока" if poll.deadline_at

        lines = []
        lines << "Включено: #{enabled_features.join(', ')}" unless enabled_features.empty?
        lines << "Правильные варианты: #{poll.correct_answers.join(', ')}" if poll.correct_answers?
        lines << "Дедлайн: #{format_deadline(poll.deadline_at)}" if poll.deadline_at
        lines
      end

      def settings_menu_text(settings = current_draft_settings)
        lines = ["Настройки опроса:"]

        SETTING_ITEMS.each_with_index do |(key, title), index|
          lines << "#{index + 1}. #{title}: #{setting_enabled?(settings, key) ? 'вкл' : 'выкл'}"
          if key == "correct_answers" && Array(settings["correct_answers"]).any?
            lines << "   Правильные варианты: #{Array(settings['correct_answers']).join(', ')}"
          end
          if key == "deadline_at" && present_text?(settings["deadline_at"])
            lines << "   Дедлайн: #{format_deadline(settings['deadline_at'])}"
          end
        end

        lines << ""
        lines << "Отправьте номер настройки, чтобы изменить её."
        lines << "Отправьте /done для создания опроса или /cancel для отмены."
        lines.join("\n")
      end

      def current_draft_settings
        settings = Models::PollRecord::DEFAULT_SETTINGS.each_with_object({}) do |(key, value), memo|
          memo[key] = value.is_a?(Array) ? value.dup : value
        end

        session.data.fetch("draft_settings", {}).to_h.each do |key, value|
          settings[key.to_s] = value.is_a?(Array) ? value.map(&:to_s) : value
        end

        settings["correct_answers"] = Array(settings["correct_answers"]).map { |option| option.to_s.strip }.reject(&:empty?).uniq
        settings["deadline_at"] = nil unless present_text?(settings["deadline_at"])
        settings
      end

      def draft_payload(overrides = {})
        {
          "draft_question" => session.data.fetch("draft_question"),
          "draft_options" => Array(session.data["draft_options"]).dup,
          "draft_settings" => current_draft_settings
        }.merge(overrides)
      end

      def resolve_draft_option_choices(input)
        tokens = input.to_s.split(/[,;\n]+/).map(&:strip).reject(&:empty?)
        raise ArgumentError, "Нужно указать хотя бы один вариант." if tokens.empty?

        tokens.map { |token| resolve_draft_option(token) }.uniq
      end

      def parse_deadline_input(input, reference_time: Time.now)
        raw_value = input.to_s.strip
        raise ArgumentError, "Укажите срок завершения опроса." if raw_value.empty?

        deadline =
          if raw_value.match?(/\A\d+\z/)
            reference_time + (raw_value.to_i * 60)
          else
            Time.parse(raw_value)
          end

        raise ArgumentError, "Срок завершения должен быть в будущем." unless deadline > reference_time

        deadline.utc.iso8601
      rescue ArgumentError => e
        raise e if e.message == "Срок завершения должен быть в будущем."

        raise ArgumentError, "Укажите дедлайн в формате YYYY-MM-DD HH:MM или числом минут от текущего момента."
      end

      def poll_status(poll)
        return "закрыт" if poll.closed?
        return "открыт до #{format_deadline(poll.deadline_at)}" if poll.deadline_at

        "открыт"
      end

      def setting_enabled?(settings, key)
        case key
        when "correct_answers"
          Array(settings["correct_answers"]).any?
        when "deadline_at"
          present_text?(settings["deadline_at"])
        else
          settings[key] == true
        end
      end

      def resolve_draft_option(input)
        draft_options = Array(session.data["draft_options"]).map(&:to_s)
        value = input.to_s.strip
        raise ArgumentError, "Вариант ответа не указан." if value.empty?

        if value.match?(/\A\d+\z/)
          option = draft_options[value.to_i - 1]
          raise ArgumentError, "Вариант с номером '#{value}' не найден." unless option

          return option
        end

        normalized_value = normalize_text(value)
        option = draft_options.find { |candidate| normalize_text(candidate) == normalized_value }
        raise ArgumentError, "Вариант '#{value}' не найден." unless option

        option
      end

      def format_deadline(value)
        return nil unless present_text?(value)

        Time.parse(value.to_s).utc.strftime("%Y-%m-%d %H:%M UTC")
      rescue ArgumentError
        value.to_s
      end

      def present_text?(value)
        !value.to_s.strip.empty?
      end

      def normalize_text(value)
        value.to_s.strip.downcase
      end
    end
  end
end
