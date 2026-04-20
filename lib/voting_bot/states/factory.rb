# frozen_string_literal: true

module VotingBot
  module States
    class Factory
      def build(state_name)
        case state_name
        when "idle" then Idle.new
        when "awaiting_question" then AwaitingQuestion.new
        when "awaiting_options" then AwaitingOptions.new
        when "awaiting_vote_choice" then AwaitingVoteChoice.new
        else
          Idle.new
        end
      end
    end
  end
end
