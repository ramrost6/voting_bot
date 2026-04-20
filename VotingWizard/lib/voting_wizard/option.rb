# frozen_string_literal: true

module VotingWizard
  class Option
    attr_reader :text, :votes_count

    def initialize(text)
      raise InvalidOptionError, "Option text cannot be empty" if text.nil? || text.strip.empty?

      @text = text.strip
      @votes_count = 0
    end

    def add_vote
      @votes_count += 1
    end
  end
end