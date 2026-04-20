# frozen_string_literal: true

require_relative "test_helper"

class MessageRouterTest
  include SimpleAssertions

  def run
    setup
    test_creates_poll_persists_state_and_accepts_vote
    puts "message_router_test.rb: OK"
  ensure
    teardown
  end

  private

  def setup
    @tmpdir = Dir.mktmpdir
    @storage_path = File.join(@tmpdir, "bot_state.json")
    @store = VotingBot::Persistence::JsonStore.new(@storage_path)
    @client = FakeTelegramClient.new
    @router = VotingBot::MessageRouter.new(store: @store, client: @client)
    @update_id = 0
  end

  def teardown
    FileUtils.remove_entry(@tmpdir) if @tmpdir && File.exist?(@tmpdir)
  end

  def test_creates_poll_persists_state_and_accepts_vote
    @router.handle(build_update("/new_poll"))
    session = @store.fetch_session(10)
    assert_equal "awaiting_question", session.state

    @router.handle(build_update("Любимый язык программирования?"))
    session = @store.fetch_session(10)
    assert_equal "awaiting_options", session.state

    @router.handle(build_update("Ruby"))
    @router.handle(build_update("Go"))
    @router.handle(build_update("/done"))

    session = @store.fetch_session(10)
    assert_equal "idle", session.state

    poll = @store.find_poll(1)
    refute_nil poll
    assert_equal "Любимый язык программирования?", poll.question
    assert_equal ["Ruby", "Go"], poll.options

    reloaded_store = VotingBot::Persistence::JsonStore.new(@storage_path)
    reloaded_poll = reloaded_store.find_poll(1)
    assert_equal ["Ruby", "Go"], reloaded_poll.options

    @router.handle(build_update("/vote 1"))
    @router.handle(build_update("1"))

    voted_poll = @store.find_poll(1)
    assert_equal 1, voted_poll.total_votes
    assert_equal({"Ruby" => 1, "Go" => 0}, voted_poll.results)
  end

  private

  def build_update(text)
    @update_id += 1
    VotingBot::Models::Update.new(
      update_id: @update_id,
      chat_id: 100,
      user_id: 10,
      text: text,
      username: "tester",
      first_name: "Test"
    )
  end
end

MessageRouterTest.new.run
