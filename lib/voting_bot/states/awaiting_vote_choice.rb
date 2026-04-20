# frozen_string_literal: true

module VotingBot
  module States
    class AwaitingVoteChoice < Base
      private

      def handle
        if update.command? && update.command_name == "cancel"
          session.reset!
          return reply("Голосование отменено.")
        end

        poll_id = session.data["poll_id"]
        poll = store.find_poll(poll_id)
        raise ArgumentError, "Опрос не найден." unless poll

        poll.vote(user_id: update.user_id, option_input: update.body)
        store.update_poll(poll)
        session.reset!

        reply(
          [
            "Голос принят в опросе ##{poll.id}.",
            "Текущие результаты:",
            results_text(poll)
          ].join("\n")
        )
      end
    end
  end
end
