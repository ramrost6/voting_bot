# frozen_string_literal: true

require "voting_wizard"

RSpec.describe VotingWizard do
  it "has a version number" do
    expect(VotingWizard::VERSION).not_to be_nil
  end
end