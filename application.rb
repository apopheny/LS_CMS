require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, escape_html: true
end

before do
  @public_files = Dir.children('./data/')
end

get '/' do
  erb :index
end

get '/:file_name' do
  name = params[:file_name]
  @file_content = File.readlines("data/#{name}")
  erb :files
end