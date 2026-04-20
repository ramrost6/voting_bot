# frozen_string_literal: true

module VotingBot
  class StateContext
    attr_reader :update, :session, :store, :responder

    def initialize(update:, session:, store:, responder:)
      @update = update
      @session = session
      @store = store
      @responder = responder
    end
  end
end
