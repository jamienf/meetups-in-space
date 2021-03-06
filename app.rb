require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/flash'
require 'omniauth-github'
require 'pry'

require_relative 'config/application'

Dir['app/**/*.rb'].each { |file| require_relative file }

#######################
#######  METHODS  #####
#######################

helpers do
  def current_user
    user_id = session[:user_id]
    @current_user ||= User.find(user_id) if user_id.present?
  end

  def signed_in?
    current_user.present?
  end
end

def set_current_user(user)
  session[:user_id] = user.id
end

def authenticate!
  unless signed_in?
    flash[:notice] = 'You need to sign in if you want to do that!'
    redirect '/'
  end
end

#######################
#######  ROUTES  ######
#######################

get '/' do
  erb :index
end

get '/meetups_list' do
  @meetups = Meetup.all
  erb :meetups_list
end

get '/meetups/:id' do
  @meetups = Meetup.find(params[:id])
  @users = @meetups.users

  erb :meetups
end

get '/create_meetup' do

  erb :create_meetup
end

post '/meetups/:id/leave' do
  @user_id = current_user[:id]
  @meetup_id = params[:id]

  remove_user = Rsvp.find_by(user_id: @user_id, meetup_id: @meetup_id)
  remove_user.destroy
  flash[:notice] = "You have successfully been removed from this meetup"
  redirect "/meetups/#{@meetup_id}"
end

post '/meetups/:id/join' do
  @user_id = current_user[:id]
  @meetup_id = params[:id]

  Rsvp.create(user_id: @user_id, meetup_id: @meetup_id)
  flash[:notice] = "You have successfully joined this meetup"
  redirect "/meetups/#{@meetup_id}"
end


post '/create_meetup' do
  @name = params[:name]
  @description = params[:description]
  @location = params[:location]
  @all = Meetup.create(name: @name, description: @description, location: @location)

  if @name.empty? || @description.empty? || @location.empty?
    flash[:notice] = "You must enter information in every field"

    redirect "/create_meetup"
  else
     flash[:notice] = "You have successfully created a meetup."
     redirect "/meetups/#{@all[:id]}"
  end
end

get '/auth/github/callback' do
  auth = env['omniauth.auth']

  user = User.find_or_create_from_omniauth(auth)
  set_current_user(user)
  flash[:notice] = "You're now signed in as #{user.username}!"

  redirect '/meetups_list'
end

get '/sign_out' do
  session[:user_id] = nil
  flash[:notice] = "You have been signed out."

  redirect '/'
end

get '/example_protected_page' do
  authenticate!
end
