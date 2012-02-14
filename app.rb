require 'rubygems'
require 'sinatra'
require 'haml'
require 'pivotal-tracker'

def get_stories
  PivotalTracker::Client.token = user[:token]
  projects = PivotalTracker::Project.all
  stories = projects.map {|project|
    project.stories.all(:owner => user[:name])
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

get '/stories', :auth => :user do
  @stories = get_stories
  haml :stories
end

get '/logout' do
  session[:token] = nil
  redirect to('/login')
end