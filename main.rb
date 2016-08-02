require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'your_secret'

get '/' do
  "Hello World. This is some sample text"
end

get '/new_game' do #first screen, gets users' name
end

get '/bet' do
end

get '/game' do
end

get '/game_over' do
end
