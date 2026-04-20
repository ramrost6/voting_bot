# frozen_string_literal: true

module VotingBot
  class MessageRouter
    def initialize(store:, client:)
      @store = store
      @client = client
      @state_factory = States::Factory.new
    end

    def handle(update)
      session = @store.fetch_session(update.user_id)
      responder = Responder.new(client: @client, chat_id: update.chat_id)
      context = StateContext.new(
        update: update,
        session: session,
        store: @store,
        responder: responder
      )

      @state_factory.build(session.state).call(context)
      @store.save_session(session)
    rescue StandardError => e
      session&.reset!
      @store.save_session(session) if session
      responder&.reply("Не удалось обработать сообщение: #{e.message}")
      warn("Router error: #{e.class}: #{e.message}")
    end
  end
end
