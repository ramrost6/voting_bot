# frozen_string_literal: true

module VotingBot
  module Models
    class PollRecord
      DEFAULT_SETTINGS = {
        "show_voter_names" => false,
        "multiple_answers" => false,
        "allow_option_addition" => false,
        "allow_vote_change" => false,
        "random_order" => false,
        "correct_answers" => [],
        "deadline_at" => nil
      }.freeze

      attr_reader :id, :creator_id, :question, :options, :votes, :created_at, :settings, :display_order

      def initialize(
        id:,
        creator_id:,
        question:,
        options:,
        votes: {},
        created_at: Time.now.utc.iso8601,
        settings: {},
        display_order: nil
      )
        @id = id.to_i
        @creator_id = creator_id.to_s
        @question = question.to_s.strip
        @options = options.map { |option| option.to_s.strip }
        @created_at = created_at
        @settings = normalize_settings(settings)
        @votes = normalize_votes(votes)
        @display_order = normalize_display_order(display_order)

        validate!
      end

      def vote(user_id:, option_input:, display_name: nil, voted_at: Time.now.utc)
        raise VotingBot::PollClosedError, "Опрос уже закрыт." if closed?(voted_at)

        user_key = user_id.to_s
        if @votes.key?(user_key) && !allow_vote_change?
          raise VotingWizard::DuplicateVoteError, "Пользователь уже голосовал. Изменение ответа отключено."
        end

        @votes[user_key] = {
          "choices" => resolve_choices(option_input),
          "display_name" => normalize_display_name(display_name, fallback: user_key)
        }
        self
      end

      def add_option(text, added_at: Time.now.utc)
        raise VotingBot::PollClosedError, "Опрос уже закрыт." if closed?(added_at)
        unless allow_option_addition?
          raise VotingBot::OptionAdditionNotAllowedError, "Добавление вариантов отключено для этого опроса."
        end

        preview_poll = VotingWizard::Poll.new(@question)
        @options.each { |option| preview_poll.add_option(option) }
        preview_poll.add_option(text)

        option_text = preview_poll.options.last.text
        @options << option_text
        insert_into_display_order(option_text)
        self
      end

      def results
        @options.each_with_object({}) do |option, hash|
          hash[option] = 0
        end.tap do |hash|
          @votes.each_value do |vote|
            Array(vote["choices"]).each do |choice|
              hash[choice] += 1 if hash.key?(choice)
            end
          end
        end
      end

      def winner
        return nil if @options.empty?
        return nil if total_votes.zero?

        ordered_results = results
        max_votes = ordered_results.values.max
        winners = ordered_results.select { |_, votes_count| votes_count == max_votes && votes_count.positive? }.keys
        return nil if winners.size != 1

        winners.first
      end

      def percentage_for(option_text)
        canonical_option = resolve_existing_option(option_text)
        return 0.0 if total_votes.zero?

        ((results.fetch(canonical_option, 0).to_f / total_votes) * 100).round(2)
      end

      def total_votes
        @votes.size
      end

      def total_selections
        @votes.values.sum { |vote| Array(vote["choices"]).size }
      end

      def display_options
        @display_order.dup
      end

      def selected_options_for(user_id)
        raw_vote = @votes[user_id.to_s]
        return [] unless raw_vote

        Array(raw_vote["choices"]).dup
      end

      def option_voter_names(option_text)
        canonical_option = resolve_existing_option(option_text)

        @votes.values.filter_map do |vote|
          next unless Array(vote["choices"]).include?(canonical_option)

          display_name = vote["display_name"].to_s.strip
          display_name unless display_name.empty?
        end.sort_by(&:downcase)
      end

      def correct_selection_for?(user_id)
        return nil unless correct_answers?

        choices = selected_options_for(user_id)
        return nil if choices.empty?

        if multiple_answers?
          choices.sort == correct_answers.sort
        else
          correct_answers.include?(choices.first)
        end
      end

      def show_voter_names?
        @settings["show_voter_names"]
      end

      def multiple_answers?
        @settings["multiple_answers"]
      end

      def allow_option_addition?
        @settings["allow_option_addition"]
      end

      def allow_vote_change?
        @settings["allow_vote_change"]
      end

      def random_order?
        @settings["random_order"]
      end

      def correct_answers
        Array(@settings["correct_answers"]).dup
      end

      def correct_answers?
        correct_answers.any?
      end

      def deadline_at
        raw_value = @settings["deadline_at"].to_s.strip
        return nil if raw_value.empty?

        raw_value
      end

      def deadline_time
        return nil unless deadline_at

        Time.parse(deadline_at).utc
      end

      def closed?(reference_time = Time.now.utc)
        limit = deadline_time
        return false unless limit

        limit <= reference_time.utc
      end

      def to_h
        {
          "id" => @id,
          "creator_id" => @creator_id,
          "question" => @question,
          "options" => @options,
          "votes" => serialized_votes,
          "created_at" => @created_at,
          "settings" => serialized_settings,
          "display_order" => @display_order
        }
      end

      def self.from_h(payload)
        new(
          id: payload.fetch("id"),
          creator_id: payload.fetch("creator_id"),
          question: payload.fetch("question"),
          options: payload.fetch("options"),
          votes: payload.fetch("votes", {}),
          created_at: payload.fetch("created_at", Time.now.utc.iso8601),
          settings: payload.fetch("settings", {}),
          display_order: payload["display_order"]
        )
      end

      private

      def validate!
        preview_poll = VotingWizard::Poll.new(@question)
        @options.each { |option| preview_poll.add_option(option) }

        raise ArgumentError, "Порядок отображения вариантов повреждён." unless display_order_valid?

        invalid_correct_answers = correct_answers - @options
        unless invalid_correct_answers.empty?
          raise VotingWizard::OptionNotFoundError, "Правильный вариант '#{invalid_correct_answers.first}' не найден."
        end

        @votes.each_value do |vote|
          choices = Array(vote["choices"])
          raise VotingWizard::OptionNotFoundError, "Вариант ответа не указан." if choices.empty?
          if !multiple_answers? && choices.size > 1
            raise ArgumentError, "Для одиночного голосования можно выбрать только один вариант."
          end

          choices.each { |choice| resolve_existing_option(choice) }
        end

        deadline_time
      end

      def normalize_settings(settings)
        raw_settings = DEFAULT_SETTINGS.each_with_object({}) do |(key, value), memo|
          memo[key] = value.is_a?(Array) ? value.dup : value
        end

        settings.to_h.each do |key, value|
          raw_settings[key.to_s] = value
        end

        raw_settings["show_voter_names"] = truthy?(raw_settings["show_voter_names"])
        raw_settings["multiple_answers"] = truthy?(raw_settings["multiple_answers"])
        raw_settings["allow_option_addition"] = truthy?(raw_settings["allow_option_addition"])
        raw_settings["allow_vote_change"] = truthy?(raw_settings["allow_vote_change"])
        raw_settings["random_order"] = truthy?(raw_settings["random_order"])
        raw_settings["correct_answers"] = Array(raw_settings["correct_answers"]).map { |option| option.to_s.strip }.reject(&:empty?).uniq
        raw_settings["deadline_at"] = normalize_deadline(raw_settings["deadline_at"])
        raw_settings
      end

      def normalize_votes(votes)
        votes.to_h.each_with_object({}) do |(user_id, raw_vote), memo|
          memo[user_id.to_s] = normalize_vote(raw_vote, fallback_name: user_id.to_s)
        end
      end

      def normalize_vote(raw_vote, fallback_name:)
        case raw_vote
        when String
          {
            "choices" => [raw_vote.to_s.strip].reject(&:empty?),
            "display_name" => fallback_name
          }
        when Array
          {
            "choices" => raw_vote.map { |choice| choice.to_s.strip }.reject(&:empty?).uniq,
            "display_name" => fallback_name
          }
        when Hash
          {
            "choices" => normalize_choices(extract_value(raw_vote, "choices", "option", "option_text")),
            "display_name" => normalize_display_name(extract_value(raw_vote, "display_name"), fallback: fallback_name)
          }
        else
          {
            "choices" => [raw_vote.to_s.strip].reject(&:empty?),
            "display_name" => fallback_name
          }
        end
      end

      def normalize_choices(value)
        Array(value).map { |choice| choice.to_s.strip }.reject(&:empty?).uniq
      end

      def normalize_display_name(display_name, fallback:)
        normalized_value = display_name.to_s.strip
        return fallback if normalized_value.empty?

        normalized_value
      end

      def normalize_display_order(display_order)
        default_order = random_order? ? @options.shuffle : @options.dup
        return default_order unless display_order

        normalized_order = Array(display_order).map { |option| option.to_s.strip }.reject(&:empty?)
        return default_order if normalized_order.empty?

        preserved_order = normalized_order.select { |option| @options.include?(option) }.uniq
        preserved_order + (@options - preserved_order)
      end

      def serialized_votes
        @votes.each_with_object({}) do |(user_id, vote), memo|
          memo[user_id] = {
            "choices" => Array(vote["choices"]).dup,
            "display_name" => vote["display_name"].to_s
          }
        end
      end

      def serialized_settings
        DEFAULT_SETTINGS.each_with_object({}) do |(key, _), memo|
          memo[key] = key == "correct_answers" ? correct_answers : @settings[key]
        end
      end

      def resolve_choices(option_input)
        input = option_input.to_s.strip
        raise VotingWizard::OptionNotFoundError, "Вариант ответа не указан." if input.empty?

        raw_choices = multiple_answers? ? split_selection_input(input) : [input]
        choices = raw_choices.map { |choice| resolve_option(choice) }.uniq
        raise VotingWizard::OptionNotFoundError, "Нужно выбрать хотя бы один вариант." if choices.empty?

        choices
      end

      def split_selection_input(input)
        input.split(/[,;\n]+/).map(&:strip).reject(&:empty?)
      end

      def resolve_option(option_input)
        input = option_input.to_s.strip
        raise VotingWizard::OptionNotFoundError, "Вариант ответа не указан." if input.empty?

        if input.match?(/\A\d+\z/)
          option = @display_order[input.to_i - 1]
          raise VotingWizard::OptionNotFoundError, "Вариант с номером '#{input}' не найден." unless option

          return option
        end

        resolve_existing_option(input)
      end

      def resolve_existing_option(option_input)
        normalized_input = normalize(option_input)
        option = @options.find { |candidate| normalize(candidate) == normalized_input }
        raise VotingWizard::OptionNotFoundError, "Вариант '#{option_input}' не найден." unless option

        option
      end

      def insert_into_display_order(option_text)
        if random_order?
          insertion_index = @display_order.empty? ? 0 : rand(0..@display_order.size)
          @display_order.insert(insertion_index, option_text)
        else
          @display_order << option_text
        end
      end

      def display_order_valid?
        @display_order.uniq.size == @options.size &&
          (@display_order - @options).empty? &&
          (@options - @display_order).empty?
      end

      def normalize_deadline(value)
        raw_value = value.to_s.strip
        return nil if raw_value.empty?

        Time.parse(raw_value).utc.iso8601
      rescue ArgumentError
        raise ArgumentError, "Некорректный срок завершения опроса."
      end

      def extract_value(hash, *keys)
        keys.each do |key|
          return hash[key] if hash.key?(key)

          symbolized_key = key.to_sym
          return hash[symbolized_key] if hash.key?(symbolized_key)
        end

        nil
      end

      def normalize(value)
        value.to_s.strip.downcase
      end

      def truthy?(value)
        value == true || value.to_s == "true" || value.to_s == "1"
      end
    end
  end
end
