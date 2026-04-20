# frozen_string_literal: true

require "voting_wizard"

RSpec.describe "PollMaster integration" do
  it "runs full poll flow" do
    poll = VotingWizard::Poll.new("Best backend language?")
    poll.add_option("Ruby")
    poll.add_option("Python")
    poll.add_option("Go")

    poll.vote(user: "Ivan", option: "Ruby")
    poll.vote(user: "Maria", option: "Ruby")
    poll.vote(user: "Alex", option: "Go")

    expect(poll.total_votes).to eq(3)
    expect(poll.results).to eq({
      "Ruby" => 2,
      "Python" => 0,
      "Go" => 1
    })
    expect(poll.winner).to eq("Ruby")
    expect(poll.percentage_for("Ruby")).to eq(66.67)
  end
end