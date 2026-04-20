# frozen_string_literal: true

module VotingBot
  class UpdateLoop
    RETRY_DELAY = 3

    def initialize(client:, router:, polling_timeout: 20)
      @client = client
      @router = router
      @polling_timeout = polling_timeout
      @offset = nil
    end

    def run
      loop do
        updates = @client.get_updates(offset: @offset, timeout: @polling_timeout)
        updates.each do |update|
          @router.handle(update)
          @offset = update.update_id + 1
        end
      rescue StandardError => e
        warn("Polling error: #{e.class}: #{e.message}")
        sleep(RETRY_DELAY)
      end
    end
  end
end
