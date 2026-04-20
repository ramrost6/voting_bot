# frozen_string_literal: true

require "voting_wizard"

RSpec.describe VotingWizard::Option do
  describe "#initialize" do
    it "creates option with text" do
      option = described_class.new("Ruby")

      expect(option.text).to eq("Ruby")
      expect(option.votes_count).to eq(0)
    end

    it "strips spaces from text" do
      option = described_class.new("  Ruby  ")

      expect(option.text).to eq("Ruby")
    end

    it "raises error for empty text" do
      expect { described_class.new("   ") }
        .to raise_error(VotingWizard::InvalidOptionError)
    end
  end

  describe "#add_vote" do
    it "increments votes count" do
      option = described_class.new("Ruby")

      option.add_vote
      option.add_vote

      expect(option.votes_count).to eq(2)
    end
  end
end