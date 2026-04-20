# frozen_string_literal: true

module VotingBot
  module Models
    class Session
      IDLE_STATE = "idle".freeze

      attr_accessor :state, :data
      attr_reader :user_id

      def initialize(user_id:, state: IDLE_STATE, data: {})
        @user_id = user_id.to_s
        @state = state
        @data = data.transform_keys(&:to_s)
      end

      def transition_to(state, data = {})
        @state = state
        @data = data.transform_keys(&:to_s)
      end

      def reset!
        transition_to(IDLE_STATE, {})
      end

      def to_h
        {
          "user_id" => @user_id,
          "state" => @state,
          "data" => @data
        }
      end

      def self.from_h(payload)
        new(
          user_id: payload.fetch("user_id"),
          state: payload.fetch("state", IDLE_STATE),
          data: payload.fetch("data", {})
        )
      end
    end
  end
end
