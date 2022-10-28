ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../application"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"
    file_names = %w(about.txt changes.txt history.txt)
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    file_names.each do |file|
      assert_includes last_response.body, file
    end
  end

  def test_history_txt
    get '/history.txt'
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Ruby 1.4 released"
  end
end
