# frozen_string_literal: true

require_relative "lib/voting_wizard/version"

Gem::Specification.new do |spec|
  spec.name = "voting_wizard"
  spec.version = VotingWizard::VERSION
  spec.authors = ["Roman", "Alexander"]
  spec.email = ["ramrost666@gmail.com", "alepon1337@mail.ru"]

  spec.summary = "Ruby gem for creating polls and voting"
  spec.description = "VotingWizard is a Ruby gem for creating polls, adding options, collecting votes, and calculating results."
  spec.homepage = "https://github.com/zibertszn/VotingWizard"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/zibertszn/VotingWizard"

  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*", "exe/*", "README.md", "LICENSE.txt"]
  end

  spec.bindir = "exe"
  spec.executables = ["voting_wizard"]
  spec.require_paths = ["lib"]
end
