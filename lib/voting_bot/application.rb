# frozen_string_literal: true

module VotingBot
  class Application
    def initialize(config: Config.new)
      @config = config
    end

    def run
      store = Persistence::JsonStore.new(@config.storage_path)
      client = TelegramClient.new(token: @config.token)
      router = MessageRouter.new(store: store, client: client)
      loop_runner = UpdateLoop.new(
        client: client,
        router: router,
        polling_timeout: @config.polling_timeout
      )

      puts "Voting bot started"
      loop_runner.run
    rescue Interrupt
      puts "\nVoting bot stopped"
    end
  end
end
