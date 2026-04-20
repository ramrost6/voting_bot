# frozen_string_literal: true

module VotingWizard
  class Poll
    attr_reader :question, :options

    def initialize(question)
      raise ArgumentError, "Question cannot be empty" if question.nil? || question.strip.empty?

      @question = question.strip
      @options = []
      @votes = []
    end

    def add_option(text)
      normalized_text = normalize(text)

      if option_exists?(normalized_text)
        raise DuplicateOptionError, "Option '#{text}' already exists"
      end

      @options << Option.new(text)
      self
    end

    def vote(user:, option:)
      raise DuplicateVoteError, "User '#{user}' has already voted" if voted?(user)

      selected_option = find_option(option)
      raise OptionNotFoundError, "Option '#{option}' not found" unless selected_option

      @votes << Vote.new(user: user, option_text: selected_option.text)
      selected_option.add_vote
      self
    end

    def results
      @options.each_with_object({}) do |option, hash|
        hash[option.text] = option.votes_count
      end
    end

    def total_votes
      @votes.size
    end

    def voted?(user)
      normalized_user = normalize(user)
      @votes.any? { |vote| normalize(vote.user) == normalized_user }
    end

    def winner
      return nil if @options.empty?
      return nil if total_votes.zero?

      max_votes = @options.map(&:votes_count).max
      winners = @options.select { |option| option.votes_count == max_votes }

      return nil if winners.size > 1

      winners.first.text
    end

    def percentage_for(option_text)
      option = find_option(option_text)
      raise OptionNotFoundError, "Option '#{option_text}' not found" unless option

      return 0.0 if total_votes.zero?

      ((option.votes_count.to_f / total_votes) * 100).round(2)
    end

    private

    def find_option(text)
      normalized_text = normalize(text)
      @options.find { |option| normalize(option.text) == normalized_text }
    end

    def option_exists?(text)
      @options.any? { |option| normalize(option.text) == text }
    end

    def normalize(value)
      value.to_s.strip.downcase
    end
  end
end
