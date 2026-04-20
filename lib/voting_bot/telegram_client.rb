# frozen_string_literal: true

module VotingBot
  class TelegramClient
    API_BASE = "https://api.telegram.org".freeze

    def initialize(token:)
      @token = token
    end

    def get_updates(offset:, timeout:)
      payload = {
        timeout: timeout,
        allowed_updates: ["message"]
      }
      payload[:offset] = offset if offset

      response = post("getUpdates", payload)
      response.fetch("result", []).filter_map { |raw_update| Models::Update.from_telegram(raw_update) }
    end

    def send_message(chat_id:, text:)
      post("sendMessage", chat_id: chat_id, text: text)
    end

    private

    def post(method_name, payload)
      uri = URI("#{API_BASE}/bot#{@token}/#{method_name}")
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = JSON.generate(payload)

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      parsed_body = JSON.parse(response.body)
      return parsed_body if response.is_a?(Net::HTTPSuccess) && parsed_body["ok"]

      description = parsed_body["description"] || response.body
      raise TelegramApiError, "Telegram API request failed: #{description}"
    rescue JSON::ParserError => e
      raise TelegramApiError, "Telegram API returned invalid JSON: #{e.message}"
    end
  end
end
