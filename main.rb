require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'your_secret'

helpers do
  def calculate_total(card_values)
    hand = card_values.map {|card| card[1]}
    hand_total = 0
    hand.each do |value|
      if value == "A"
        hand_total += 11
      elsif value.to_i == 0
        hand_total += 10
      else
        hand_total += value.to_i
      end
    end
    hand.select{|value| value == "A"}.count.times do
      hand_total -= 10 if hand_total > 21
    end
    hand_total
  end
end

before do
  @show_hit_or_stay_buttons = true
end

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

post '/game/player/hit' do
  session[:player_hand] << session[:deck].pop
  if calculate_total(session[:player_hand]) > 21
    @error = "Sorry, you've busted."
    @show_hit_or_stay_buttons = false
  end
  erb :game
end

post '/game/player/stay' do
  @success = "You have chosen to stay"
  @show_hit_or_stay_buttons = false
  erb :game
end

get '/game_over' do
end
