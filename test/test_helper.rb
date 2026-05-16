ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Avoid CI flakes from DB fan-out by defaulting to 1 worker in CI.
    workers = ENV.fetch("PARALLEL_WORKERS", ENV["CI"] ? "1" : "number_of_processors")
    parallelize(workers: workers == "number_of_processors" ? :number_of_processors : workers.to_i)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
