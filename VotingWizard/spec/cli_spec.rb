# frozen_string_literal: true

require "json"
require "stringio"
require "tmpdir"
require "voting_wizard"

RSpec.describe VotingWizard::CLI do
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  describe "#run" do
    it "runs an interactive voting session" do
      stdin = StringIO.new(<<~INPUT)
        Favorite language?
        Ruby
        Python

        2
        Ivan
        1
        3
        4
        6
      INPUT

      exit_code = described_class.new(stdin: stdin, stdout: stdout, stderr: stderr).run

      expect(exit_code).to eq(0)
      expect(stdout.string).to include("Results for: Favorite language?")
      expect(stdout.string).to include("- Ruby: 1 vote(s) (100.00%)")
      expect(stdout.string).to include("Winner: Ruby")
      expect(stderr.string).to eq("")
    end

    it "still allows voting by option name" do
      stdin = StringIO.new(<<~INPUT)
        Favorite language?
        Ruby
        Python

        2
        Ivan
        Python
        3
        6
      INPUT

      exit_code = described_class.new(stdin: stdin, stdout: stdout, stderr: stderr).run

      expect(exit_code).to eq(0)
      expect(stdout.string).to include("- Python: 1 vote(s) (100.00%)")
      expect(stderr.string).to eq("")
    end

    it "supports bootstrapping from command line options" do
      stdin = StringIO.new("6\n")

      exit_code = described_class.new(stdin: stdin, stdout: stdout, stderr: stderr).run(
        ["--question", "Best language?", "--option", "Ruby", "--option", "Python"]
      )

      expect(exit_code).to eq(0)
      expect(stdout.string).to include("Poll: Best language?")
      expect(stderr.string).to eq("")
    end

    it "saves results to a json file" do
      Dir.mktmpdir do |dir|
        export_path = File.join(dir, "results.json")
        stdin = StringIO.new(<<~INPUT)
          Favorite language?
          Ruby
          Python

          2
          Ivan
          Ruby
          5
          #{export_path}
          6
        INPUT

        exit_code = described_class.new(stdin: stdin, stdout: stdout, stderr: stderr).run

        payload = JSON.parse(File.read(export_path))

        expect(exit_code).to eq(0)
        expect(stdout.string).to include("Results saved to #{export_path}")
        expect(payload["question"]).to eq("Favorite language?")
        expect(payload["winner"]).to eq("Ruby")
        expect(payload.dig("results", "Ruby", "votes")).to eq(1)
        expect(payload.dig("results", "Ruby", "percentage")).to eq(100.0)
      end
    end

    it "prints an error for unsupported export format" do
      stdin = StringIO.new(<<~INPUT)
        Favorite language?
        Ruby

        5
        report.xml
        6
      INPUT

      exit_code = described_class.new(stdin: stdin, stdout: stdout, stderr: stderr).run

      expect(exit_code).to eq(0)
      expect(stderr.string).to include("Unsupported export format 'xml'")
    end

    it "prints validation errors to stderr" do
      stdin = StringIO.new(<<~INPUT)
        Favorite language?

      INPUT

      exit_code = described_class.new(stdin: stdin, stdout: stdout, stderr: stderr).run

      expect(exit_code).to eq(1)
      expect(stderr.string).to include("At least one option is required")
    end
  end
end
