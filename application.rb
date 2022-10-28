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

before do
  @public_files = Dir.children('./data/')
end

markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)

def is_markdown?(file_name)
  file_name[-3..-1] == '.md'
end

get '/' do
  @file_error = session.delete(:file_error) if session[:file_error]

  erb :index
end

get '/:file_name' do
  @name = params[:file_name].to_s

  if @public_files.include?(@name)
    @file_content = if is_markdown?(@name)
                      session[:is_markdown] = true
                      markdown(File.read("data/#{@name}"))
                    else
                      File.readlines("data/#{@name}")
                    end
    erb :files
  else
    session[:file_error] = "#{@name} does not exist."
    redirect '/'
  end
end
