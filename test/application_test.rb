ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"

require_relative "../application"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def garbage_name
    name = ''
    10.times { name << ('a'..'z').to_a.sample }
    
    name
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



  def test_invalid_file
    name = garbage_name
    
    get "/#{name}"
    assert_equal 302, last_response.status
    
    get last_response['Location']

    assert_equal 200, last_response.status
    assert_includes last_response.body, "#{name} does not exist."
    
    get '/'
    refute_includes last_response.body, "#{name} does not exist."
  end

  # test/cms_test.rb
  def test_viewing_markdown_document
    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end
end
