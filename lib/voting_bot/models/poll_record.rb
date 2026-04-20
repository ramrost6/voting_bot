# frozen_string_literal: true

module VotingBot
  module Models
    class PollRecord
      attr_reader :id, :creator_id, :question, :options, :votes, :created_at

      def initialize(id:, creator_id:, question:, options:, votes: {}, created_at: Time.now.utc.iso8601)
        @id = id.to_i
        @creator_id = creator_id.to_s
        @question = question.to_s.strip
        @options = options.map { |option| option.to_s.strip }
        @votes = votes.transform_keys(&:to_s)
        @created_at = created_at

        validate!
      end

      def vote(user_id:, option_input:)
        canonical_option = resolve_option(option_input)
        poll = to_poll
        poll.vote(user: user_id.to_s, option: canonical_option)
        @votes[user_id.to_s] = canonical_option
        self
      end

      def results
        to_poll.results
      end

      def winner
        to_poll.winner
      end

      def percentage_for(option_text)
        to_poll.percentage_for(option_text)
      end

      def total_votes
        @votes.size
      end

      def to_h
        {
          "id" => @id,
          "creator_id" => @creator_id,
          "question" => @question,
          "options" => @options,
          "votes" => @votes,
          "created_at" => @created_at
        }
      end

      def self.from_h(payload)
        new(
          id: payload.fetch("id"),
          creator_id: payload.fetch("creator_id"),
          question: payload.fetch("question"),
          options: payload.fetch("options"),
          votes: payload.fetch("votes", {}),
          created_at: payload.fetch("created_at", Time.now.utc.iso8601)
        )
      end

      def to_poll
        poll = VotingWizard::Poll.new(@question)
        @options.each { |option| poll.add_option(option) }
        @votes.each { |user_id, option_text| poll.vote(user: user_id, option: option_text) }
        poll
      end

      def resolve_option(option_input)
        input = option_input.to_s.strip
        raise VotingWizard::OptionNotFoundError, "Option cannot be empty" if input.empty?

        if input.match?(/\A\d+\z/)
          option = @options[input.to_i - 1]
          raise VotingWizard::OptionNotFoundError, "Option number '#{input}' not found" unless option

          return option
        end

        normalized_input = normalize(input)
        option = @options.find { |candidate| normalize(candidate) == normalized_input }
        raise VotingWizard::OptionNotFoundError, "Option '#{input}' not found" unless option

        option
      end

      private

      def validate!
        preview_poll = VotingWizard::Poll.new(@question)
        @options.each { |option| preview_poll.add_option(option) }
        @votes.each { |user_id, option_text| preview_poll.vote(user: user_id, option: option_text) }
      end

      def normalize(value)
        value.to_s.strip.downcase
      end
    end
  end
end
