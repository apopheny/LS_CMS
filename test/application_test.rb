ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"

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

  def setup
    3.times do
      File.open("./test/testfiles/#{garbage_name}.txt", 'w+') { |file| file.write "Lorem ipsum" }
    end
    File.open("./test/testfiles/some_text_example.txt", 'w+') { |file| file.write "Some test input" }
    File.open("./test/testfiles/changes.txt", 'w+') { |file| file.write "Changes" }
    File.open('./test/testfiles/about.md', 'w+') { |file| file.write "# Ruby is..." }

    @file_names = current_directory_files
  end

  def teardown
    FileUtils.rm Dir.glob('./test/testfiles/*.txt')
    FileUtils.rm Dir.glob('./test/testfiles/*.md')
  end

  def test_index
    get "/"
    
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    @file_names.each do |file|
      assert_includes last_response.body, file
    end
  end

  def test_return_txt_file
    get '/some_text_example.txt'
    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "Some test input"
  end

  def test_invalid_file
    name = garbage_name
    
    get "/#{name}"
    assert_equal 302, last_response.status
    
    get last_response['Location']

    assert_equal 200, last_response.status
    assert_includes last_response.body, "'#{name}' does not exist."
    
    get '/'
    refute_includes last_response.body, "'#{name}' does not exist."
  end

  # test/cms_test.rb
  def test_viewing_markdown_document
    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "<h1>Ruby is...</h1>"
  end

  def test_editing_document
    get "/changes.txt/edit"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<input type="submit")
  end

  def test_updating_document
    post "/changes.txt/edit", file_changes: "new content"

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_includes last_response.body, "'changes.txt' has been updated"

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

  def test_new_file
    get '/new_file/create'
    assert_equal 200, last_response.status

    post '/new_file/create', new_file_name: ''
    assert_equal 302, last_response.status
    get last_response["Location"]
    refute_includes current_directory_files, ''
    assert_includes last_response.body, "A filename must be provided."

    post '/new_file/create', new_file_name: 'new_file_name'
    assert_equal 302, last_response.status
    get last_response["Location"]
    refute_includes current_directory_files, 'new_file_name'
    assert_includes last_response.body, "is not a '.txt' or '.md' file."
    
    post '/new_file/create', new_file_name: 'new_file_name.txt'
    assert_equal 302, last_response.status
    get last_response["Location"]
    assert_includes last_response.body, "'new_file_name.txt' was created."
    assert_includes current_directory_files, 'new_file_name.txt'
    assert_equal 200, last_response.status
  end

  def test_delete_file
    get 'some_text_example.txt/delete'
    assert_equal 302, last_response.status
    get last_response["Location"]
    assert_includes last_response.body, "'some_text_example.txt' was deleted."
    refute_includes current_directory_files, 'some_text_example.txt'
  end

  # def test_login
  #   post 'user/login', username: 'not_admin'
  #   get last_response['Location']
  #   assert_includes last_response.body 'Invalid credentials provided.'
  # end
end
