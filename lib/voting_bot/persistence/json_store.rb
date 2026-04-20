# frozen_string_literal: true

module VotingBot
  module Persistence
    class JsonStore
      def initialize(path)
        @path = path
        FileUtils.mkdir_p(File.dirname(@path))
        @data = load_data
      end

      def fetch_session(user_id)
        raw_session = @data.fetch("sessions", {})[user_id.to_s]
        return Models::Session.new(user_id: user_id) unless raw_session

        Models::Session.from_h(raw_session)
      end

      def save_session(session)
        @data["sessions"][session.user_id] = session.to_h
        persist!
        session
      end

      def create_poll(question:, options:, creator_id:)
        poll = Models::PollRecord.new(
          id: next_poll_id,
          creator_id: creator_id,
          question: question,
          options: options
        )

        @data["polls"][poll.id.to_s] = poll.to_h
        @data["meta"]["next_poll_id"] = poll.id + 1
        persist!
        poll
      end

      def update_poll(poll)
        @data["polls"][poll.id.to_s] = poll.to_h
        persist!
        poll
      end

      def find_poll(poll_id)
        raw_poll = @data.fetch("polls", {})[poll_id.to_i.to_s]
        return nil unless raw_poll

        Models::PollRecord.from_h(raw_poll)
      end

      def list_polls
        @data.fetch("polls", {}).values.map { |raw_poll| Models::PollRecord.from_h(raw_poll) }.sort_by(&:id)
      end

      def list_polls_by_creator(creator_id)
        list_polls.select { |poll| poll.creator_id == creator_id.to_s }
      end

      private

      def load_data
        return default_data unless File.exist?(@path)

        parsed = JSON.parse(File.read(@path))
        parsed["sessions"] ||= {}
        parsed["polls"] ||= {}
        parsed["meta"] ||= {"next_poll_id" => 1}
        parsed
      rescue JSON::ParserError
        default_data
      end

      def default_data
        {
          "sessions" => {},
          "polls" => {},
          "meta" => {"next_poll_id" => 1}
        }
      end

      def next_poll_id
        @data.fetch("meta", {}).fetch("next_poll_id", 1).to_i
      end

      def persist!
        temp_path = "#{@path}.tmp"
        File.write(temp_path, JSON.pretty_generate(@data))
        FileUtils.mv(temp_path, @path, force: true)
      end
    end
  end
end
