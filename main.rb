require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'your_secret'

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    erb :new_player
  end
end

post '/new_player' do
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/bet' do
end

get '/game' do
  suits = ['Heart', 'Club', 'Diamond', 'Spade']
  card_values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(card_values).shuffle!
  session[:player_hand] = []
  session[:dealer_hand] = []
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop


  erb :game
end

get '/game_over' do
end
