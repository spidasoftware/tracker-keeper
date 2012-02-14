require 'rubygems'
require 'sinatra'
require 'haml'
require 'pivotal-tracker'

MY_STORIES = "My Stories"

def get_stories filter=nil
  PivotalTracker::Client.token = user[:token]
  projects = PivotalTracker::Project.all
  # :search parameter must be first, or the other params
  # are ignored by Project.stories.all()
  params = {:search => filter, :owner => user[:name]}
  params[:search] = filter if filter
  stories = projects.map {|project|
    project.stories.all(params)
  }.flatten.sort_by {|s| s.name}.sort_by {|s|s.current_state}
end

def authenticate token, name
  session[:name], session[:token] = name, token
end

def user
  {:token => session[:token],:name => session[:name]}
end

configure do
  enable :sessions
  set :app_file, __FILE__
  set :root, File.dirname(__FILE__)
  set(:auth) do |*roles|
    condition do
      unless logged_in?
        redirect "/login"
      end
    end
  end
end

def logged_in?
  not session[:token].nil?
end

def render_stories title, stories
  @title, @stories = title, stories
  haml :stories
end

get '/', :auth => :user do
  redirect to('/stories')
end

get '/login' do
  haml :login
end

post '/login' do
  authenticate(params[:token], params[:name])
  redirect to('/stories')
end

post '/search' do
  render_stories("Search",get_stories(params[:search]))
end

get '/stories', :auth => :user do
  render_stories(MY_STORIES,get_stories)
end

get '/logout' do
  session[:token] = nil
  redirect to('/login')
end