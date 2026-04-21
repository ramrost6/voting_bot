# frozen_string_literal: true

require_relative "test_helper"

class MessageRouterTest
  include SimpleAssertions

  def run
    run_test(:test_creates_poll_persists_state_and_accepts_vote)
    run_test(:test_supports_configurable_poll_features)
    run_test(:test_prevents_voting_after_deadline)
    puts "message_router_test.rb: OK"
  end

  private

  def run_test(method_name)
    setup
    send(method_name)
  ensure
    teardown
  end

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
    assert_equal "awaiting_poll_settings", session.state

    @router.handle(build_update("/done"))

    session = @store.fetch_session(10)
    assert_equal "idle", session.state

    poll = @store.find_poll(1)
    refute_nil poll
    assert_equal "Любимый язык программирования?", poll.question
    assert_equal ["Ruby", "Go"], poll.options
    assert_equal ["Ruby", "Go"], poll.display_options

    reloaded_store = VotingBot::Persistence::JsonStore.new(@storage_path)
    reloaded_poll = reloaded_store.find_poll(1)
    assert_equal ["Ruby", "Go"], reloaded_poll.options

    @router.handle(build_update("/vote 1"))
    @router.handle(build_update("1"))

    voted_poll = @store.find_poll(1)
    assert_equal 1, voted_poll.total_votes
    assert_equal({"Ruby" => 1, "Go" => 0}, voted_poll.results)
  end

  def test_supports_configurable_poll_features
    expected_order = nil
    srand(1234)
    expected_order = ["Ruby", "Go", "Python"].shuffle
    srand(1234)

    creator = {user_id: 30, chat_id: 300, username: "creator", first_name: "Creator"}

    @router.handle(build_update("/new_poll", **creator))
    @router.handle(build_update("Какой стек выбрать?", **creator))
    @router.handle(build_update("Ruby", **creator))
    @router.handle(build_update("Go", **creator))
    @router.handle(build_update("Python", **creator))
    @router.handle(build_update("/done", **creator))

    @router.handle(build_update("1", **creator))
    @router.handle(build_update("2", **creator))
    @router.handle(build_update("3", **creator))
    @router.handle(build_update("4", **creator))
    @router.handle(build_update("5", **creator))
    @router.handle(build_update("6", **creator))
    @router.handle(build_update("1,3", **creator))
    @router.handle(build_update("7", **creator))
    @router.handle(build_update("90", **creator))
    @router.handle(build_update("/done", **creator))

    poll = @store.find_poll(1)
    assert poll.show_voter_names?
    assert poll.multiple_answers?
    assert poll.allow_option_addition?
    assert poll.allow_vote_change?
    assert poll.random_order?
    assert_equal ["Ruby", "Python"], poll.correct_answers
    assert_equal expected_order, poll.display_options
    refute_nil poll.deadline_at
    assert_equal false, poll.closed?

    alice = {user_id: 40, chat_id: 400, username: nil, first_name: "Alice"}
    bob = {user_id: 41, chat_id: 410, username: nil, first_name: "Bob"}

    @router.handle(build_update("/vote 1", **alice))
    @router.handle(build_update("+Rust", **alice))
    @router.handle(build_update("Ruby, Rust", **alice))

    updated_poll = @store.find_poll(1)
    assert updated_poll.options.include?("Rust")
    assert_equal ["Ruby", "Rust"], updated_poll.selected_options_for(40)
    assert_equal ["Alice"], updated_poll.option_voter_names("Ruby")

    @router.handle(build_update("/vote 1", **bob))
    @router.handle(build_update("Go", **bob))
    @router.handle(build_update("/vote 1", **bob))
    @router.handle(build_update("Ruby, Python", **bob))

    changed_poll = @store.find_poll(1)
    assert_equal({"Ruby" => 2, "Go" => 0, "Python" => 1, "Rust" => 1}, changed_poll.results)
    assert_equal ["Alice", "Bob"], changed_poll.option_voter_names("Ruby")
    assert_equal true, changed_poll.correct_selection_for?(41)
    assert_equal false, changed_poll.correct_selection_for?(40)
  end

  def test_prevents_voting_after_deadline
    poll = @store.create_poll(
      question: "Срочный опрос",
      options: ["Да", "Нет"],
      creator_id: 50,
      settings: {"deadline_at" => (Time.now.utc - 60).iso8601}
    )

    @router.handle(build_update("/vote #{poll.id}", user_id: 51, chat_id: 510, username: "late_user", first_name: "Late"))

    assert_equal "idle", @store.fetch_session(51).state
    assert @client.messages.last[:text].include?("Опрос ##{poll.id} уже закрыт.")
    assert @client.messages.last[:text].include?("Результаты опроса ##{poll.id}: Срочный опрос")
  end

  def build_update(text, user_id: 10, chat_id: 100, username: "tester", first_name: "Test")
    @update_id += 1
    VotingBot::Models::Update.new(
      update_id: @update_id,
      chat_id: chat_id,
      user_id: user_id,
      text: text,
      username: username,
      first_name: first_name
    )
  end
end

MessageRouterTest.new.run
