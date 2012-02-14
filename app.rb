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
  stories = projects.map do |project|
    project.stories.all(params)
  end.flatten.sort_by do |s|
    s.name
  end.sort_by do |s|
    s.current_state
  end.map do |s|
    {
      :name  => s.name,
      :url   => s.url,
      :type  => s.story_type,
      :state => s.current_state
    }
  end
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

def render_stories title, stories, age
  @title, @stories, @age = title, stories, age
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
  stories = session[:stories].select {|s|
    s[:name].downcase.include?(params[:search].downcase)
  }
  render_stories(
    "Search",
    stories,
   session[:cache_time])
end

get '/search' do
  redirect to('/stories')
end

get '/stories', :auth => :user do
  stories = session[:stories] ||= begin
    session[:cache_time] = Time.now.strftime("%l:%M %P")
    get_stories
  end
  render_stories(MY_STORIES, stories,session[:cache_time])
end

get '/refresh', :auth => :user do
  session[:stories] = nil
  redirect to('/stories')
end

get '/logout' do
  session[:token] = nil
  redirect to('/login')
end