

module VotingWizard
  class Vote
    attr_reader :user, :option_text

    def initialize(user:, option_text:)
      raise InvalidUserError, "User cannot be empty" if user.nil? || user.strip.empty?

      @user = user.strip
      @option_text = option_text
    end
  end
end