# frozen_string_literal: true

module VotingWizard
  class Error < StandardError; end
  class DuplicateOptionError < Error; end
  class OptionNotFoundError < Error; end
  class DuplicateVoteError < Error; end
  class InvalidUserError < Error; end
  class InvalidOptionError < Error; end
end