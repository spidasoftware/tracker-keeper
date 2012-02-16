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
    project.stories.all(params).map do |story|
      to_data(project, story)
    end
  end.flatten.sort_by do |s|
    s[:name]
  end.sort_by do |s|
    priority s[:state]
  end
end

def to_data project, story
  {
    :project => project.id,
    :name  => story.name,
    :url   => story.url,
    :type  => story.story_type,
    :state => story.current_state,
    :id    => story.id
  }
end

def next_action state
  case state
    when "unscheduled"; ["Start"]
    when "unstarted"  ; ["Start"]
    when "started"    ; ["Finish"]
    when "finished"   ; ["Deliver"]
    when "delivered"  ; ["Accept","Reject"]
  end
end

def priority state
  case state
    when "unscheduled"; 4
    when "unstarted"  ; 3
    when "started"    ; 2
    when "finished"   ; 1
    when "delivered"  ; 0
    when "accepted"  ; 5
    when "rejected"  ; 2
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
    # "Search for &quot;#{params[:search]}&quot;",
    stories,
   session[:cache_time])
end

get '/search' do
  redirect to('/stories')
end

get '/stories', :auth => :user do
  if session[:cache_time] and Time.now - Time.at(session[:cache_time].to_f) > 600
    session[:stories] = nil
  end
  stories = session[:stories] ||= begin
    session[:cache_time] = Time.now.strftime("%s")
    get_stories
  end
  render_stories(MY_STORIES, stories,session[:cache_time])
end

get '/refresh', :auth => :user do
  session[:stories] = nil
  redirect to('/stories')
end

get '/load', :auth => :user do
  if @project = PivotalTracker::Project.find(params[:projectId].to_i) and
    @story = @project.stories.find(params[:storyId].to_i)
      haml :details, :layout => false
  else
    "(None)"
  end
end

post '/update', :auth => :user do
  @actions = [params[:action]]
  if project = PivotalTracker::Project.find(params[:projectId].to_i) and
    story = project.stories.find(params[:storyId].to_i)
      story.update(:current_state => params[:action].downcase + "ed")
      @actions = next_action(story.current_state)
      @stories.reject! {|s| s[:id] == story.id}
      @stories << to_data(project,story)
  end
  haml :actions, :layout => false
end

get '/logout', :auth => :user do
  session[:token] = nil
  redirect to('/login')
end