# frozen_string_literal: true

module VotingBot
  module States
    class Base
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
          lines << "##{poll.id} - #{poll.question} (вариантов: #{poll.options.size}, голосов: #{poll.total_votes})"
        end
        lines.join("\n")
      end

      def results_text(poll)
        lines = ["Результаты опроса ##{poll.id}: #{poll.question}"]
        poll.results.each do |option, votes|
          lines << "- #{option}: #{votes} (#{format('%.2f', poll.percentage_for(option))}%)"
        end

        winner = poll.winner || "ничья или пока нет голосов"
        lines << "Всего голосов: #{poll.total_votes}"
        lines << "Победитель: #{winner}"
        lines.join("\n")
      end

      def parse_poll_id(argument)
        raw_value = argument.to_s.strip
        raise ArgumentError, "Укажите ID опроса, например /vote 1" unless raw_value.match?(/\A\d+\z/)

        raw_value.to_i
      end
    end
  end
end
