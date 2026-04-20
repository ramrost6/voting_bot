
require "voting_wizard"

RSpec.describe VotingWizard::Poll do
  subject(:poll) { described_class.new("Favorite language?") }

  describe "#initialize" do
    it "creates poll with question" do
      expect(poll.question).to eq("Favorite language?")
      expect(poll.options).to eq([])
    end

    it "raises error for empty question" do
      expect { described_class.new("  ") }
        .to raise_error(ArgumentError)
    end
  end

  describe "#add_option" do
    it "adds option to poll" do
      poll.add_option("Ruby")

      expect(poll.options.map(&:text)).to eq(["Ruby"])
    end

    it "returns self" do
      expect(poll.add_option("Ruby")).to eq(poll)
    end

    it "raises error for duplicate option" do
      poll.add_option("Ruby")

      expect { poll.add_option("ruby") }
        .to raise_error(VotingWizard::DuplicateOptionError)
    end
  end

  describe "#vote" do
    before do
      poll.add_option("Ruby")
      poll.add_option("Python")
    end

    it "adds vote to selected option" do
      poll.vote(user: "Ivan", option: "Ruby")

      expect(poll.results["Ruby"]).to eq(1)
      expect(poll.total_votes).to eq(1)
    end

    it "returns self" do
      expect(poll.vote(user: "Ivan", option: "Ruby")).to eq(poll)
    end

    it "raises error if option does not exist" do
      expect { poll.vote(user: "Ivan", option: "Java") }
        .to raise_error(VotingWizard::OptionNotFoundError)
    end

    it "raises error if user votes twice" do
      poll.vote(user: "Ivan", option: "Ruby")

      expect { poll.vote(user: "Ivan", option: "Python") }
        .to raise_error(VotingWizard::DuplicateVoteError)
    end

    it "treats usernames case-insensitively" do
      poll.vote(user: "Ivan", option: "Ruby")

      expect { poll.vote(user: "ivan", option: "Python") }
        .to raise_error(VotingWizard::DuplicateVoteError)
    end
  end

  describe "#results" do
    it "returns empty results when no options" do
      expect(poll.results).to eq({})
    end

    it "returns all options with vote counts" do
      poll.add_option("Ruby")
      poll.add_option("Python")
      poll.vote(user: "Ivan", option: "Ruby")

      expect(poll.results).to eq({
        "Ruby" => 1,
        "Python" => 0
      })
    end
  end

  describe "#winner" do
    before do
      poll.add_option("Ruby")
      poll.add_option("Python")
    end

    it "returns nil when there are no votes" do
      expect(poll.winner).to be_nil
    end
     it "returns winner option text" do
      poll.vote(user: "Ivan", option: "Ruby")
      poll.vote(user: "Maria", option: "Ruby")
      poll.vote(user: "Alex", option: "Python")

      expect(poll.winner).to eq("Ruby")
    end

    it "returns nil on tie" do
      poll.vote(user: "Ivan", option: "Ruby")
      poll.vote(user: "Maria", option: "Python")

      expect(poll.winner).to be_nil
    end
  end

  describe "#percentage_for" do
    before do
      poll.add_option("Ruby")
      poll.add_option("Python")
    end

    it "returns 0.0 when there are no votes" do
      expect(poll.percentage_for("Ruby")).to eq(0.0)
    end

    it "calculates percentage correctly" do
      poll.vote(user: "Ivan", option: "Ruby")
      poll.vote(user: "Maria", option: "Ruby")
      poll.vote(user: "Alex", option: "Python")

      expect(poll.percentage_for("Ruby")).to eq(66.67)
      expect(poll.percentage_for("Python")).to eq(33.33)
    end

    it "raises error for unknown option" do
      expect { poll.percentage_for("Java") }
        .to raise_error(VotingWizard::OptionNotFoundError)
    end
  end

  describe "#voted?" do
    before do
      poll.add_option("Ruby")
    end

    it "returns false if user has not voted" do
      expect(poll.voted?("Ivan")).to be(false)
    end

    it "returns true if user has voted" do
      poll.vote(user: "Ivan", option: "Ruby")

      expect(poll.voted?("Ivan")).to be(true)
    end
  end
end