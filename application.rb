# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, escape_html: true
end

def current_directory_files
  if ENV['RACK_ENV'] == 'test'
    Dir.children('./test/testfiles/')
  else
    Dir.children('./data/')
  end
end

def path
  if ENV['RACK_ENV'] == 'test'
    'test/testfiles/'
  else
    'data/'
  end
end

def file_error?(name)
  if name.empty?
    session[:file_error] = "A filename must be provided."
  elsif current_directory_files.include?(name)
    session[:file_error] = "'#{name}' already exists."
  elsif !(name[-4..] == '.txt' || name[-3..] == '.md')
    session[:file_error] = "'#{name}' is not a '.txt' or '.md' file."
  end
end

def file_valid?(name)
  file_error?(name)
  session[:file_status] = "'#{name}' was created." unless session[:file_error]
  !session[:file_error]
end

before do
  @public_files = current_directory_files

  @file_ids = @public_files.map.with_index do |file, idx|
    [file, idx]
  end.to_h
end

def markdown
  Redcarpet::Markdown.new(Redcarpet::Render::HTML)
end

def markdown?(file_name)
  file_name[-3..] == '.md'
end

def logged_in?
  !!session[:logged_in]
end

get '/' do
  @status = if session[:file_error]
              session.delete(:file_error)
            elsif session[:file_status]
              session.delete(:file_status)
            elsif session[:welcome]
              session.delete(:welcome)
            end

  redirect '/user/login' unless logged_in?
  erb :index
end

get '/:file_name' do
  redirect '/user/login' unless logged_in?

  @name = params[:file_name].to_s

  if @public_files.include?(@name)
    @file_content = if markdown?(@name)
                      session[:markdown] = true
                      markdown(File.read(path + @name))
                    else
                      File.readlines(path + @name)
                    end
    erb :files
  else
    session[:file_error] = "'#{@name}' does not exist."
    redirect '/'
  end
end

get '/:file_name/edit' do
  redirect '/user/login' unless logged_in?

  @name = params[:file_name].to_s

  if @public_files.include?(@name)
    @file_content = File.read(path + @name)
    erb :edit
  else
    session[:file_error] = "'#{@name}' does not exist and cannot be edited."
    redirect '/'
  end
end

post '/:file_name/edit' do
  redirect '/user/login' unless logged_in?

  @name = params[:file_name].to_s
  changes = params[:file_changes]

  File.open(path + @name, 'w') { |current_file| current_file.write(changes) }

  session[:file_status] = "'#{@name}' has been updated."

  redirect '/'
end

get '/new_file/create' do
  redirect '/user/login' unless logged_in?

  erb :new_file
end

post '/new_file/create' do
  redirect '/user/login' unless logged_in?

  @new_file_name = params[:new_file_name]
  File.new(path + @new_file_name, 'w+') if file_valid?(@new_file_name)

  redirect '/'
end

get '/:file_name/delete' do
  redirect '/user/login' unless logged_in?

  @name = params[:file_name].to_s

  if current_directory_files.include?(@name)
    File.delete(path + @name)
    session[:file_status] = "'#{@name}' was deleted."
  else
    session[:file_error] = "'#{@name}' does not exist and cannot be deleted."
  end

  redirect '/'
end

get '/user/login' do
  erb :login
end

post '/user/login' do
  session[:last_user_name] = params[:username].to_s
  session[:last_password] = params[:password].to_s

  if session[:last_user_name] == 'admin' && session[:last_password] == 'secret'
    session[:logged_in] = true
    session[:welcome] = "Welcome, '#{session[:last_user_name]}'"
  else
    session[:welcome] = 'Invalid credentials provided.'
  end
  
  redirect '/'
end

get '/user/logout' do
  session[:logged_in] = false
  session[:welcome] = "'#{session[:last_user_name]}' has been signed out."
  session[:last_user_name] = ''

  redirect '/'
end