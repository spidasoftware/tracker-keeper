require 'rubygems'
require 'sinatra'
require 'haml'
require 'pivotal-tracker'

def parse_stories api_token, name
  PivotalTracker::Client.token = api_token
  projects = PivotalTracker::Project.all
  stories = projects.map {|project|
    project.stories.all(:owner => name)
  }.flatten
end

get '/' do
  haml :login
end

post '/stories' do
  if not session[:token]
    session[:token] = params[:token]
    @name = params[:name]
  end
  if token = session[:token]
    @stories = parse_stories(token, @name)
    haml :stories
  else
    haml :login
  end
end

get '/logout' do
  session[:token] = nil
  haml :login
end