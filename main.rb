require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'your_secret'

BLACKJACK = 21
DEALER_MIN = 17
INITIAL_POT = 500

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
      hand_total -= 10 if hand_total > BLACKJACK
    end
    hand_total
  end

  def card_image(card)
    suit = case card[0]
      when 'Heart' then 'hearts'
      when 'Diamond' then 'diamonds'
      when 'Club' then 'clubs'
      when 'Spade' then 'spades'
    end
    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end

  def winner!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    session[:player_pot] = session[:player_pot] + session[:player_bet]
    @success = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
  end

  def loser!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    session[:player_pot] = session[:player_pot] - session[:player_bet]
    @error = "<strong>#{session[:player_name]} loses.</strong> #{msg}"
  end

  def tie!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @success = "<strong>It's a tie!</strong> #{msg}"
  end
end

before do
  @show_hit_or_stay_buttons = true
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  session[:player_pot] = INITIAL_POT
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Player name is required."
    halt erb(:new_player)
  end
  session[:player_name] = params[:player_name]
  redirect '/bet'
end

get '/bet' do
  session[:player_bet] = nil
  erb :bet
end

post '/bet' do
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "You must place a bet."
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:player_pot]
    @error = "You bet is greater than the amount you have.  ($#{session[:player_pot]})"
    halt erb(:bet)
  else
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end
end

get '/game' do
  session[:turn] = session[:player_name]

  suits = ['Heart', 'Club', 'Diamond', 'Spade']
  card_values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(card_values).shuffle!
  session[:player_hand] = []
  session[:dealer_hand] = []
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  session[:player_hand] << session[:deck].pop
  session[:dealer_hand] << session[:deck].pop
  player_total = calculate_total(session[:player_hand])
  if player_total == BLACKJACK
    winner!("#{session[:player_name]} hit blackjack.")
  end
  erb :game
end

post '/game/player/hit' do
  session[:player_hand] << session[:deck].pop
  player_total = calculate_total(session[:player_hand])
  if player_total == BLACKJACK
    winner!("#{session[:player_name]} hit blackjack.")
  elsif player_total > BLACKJACK
    loser!("#{session[:player_name]} busted at #{player_total}.")
  end
  erb :game
end

post '/game/player/stay' do
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"
  @show_hit_or_stay_buttons = false

  dealer_total = calculate_total(session[:dealer_hand])

  if dealer_total == BLACKJACK
    loser!("Dealer hit blackjack.")
  elsif dealer_total > BLACKJACK
    winner!("Dealer busted at #{dealer_total}.")
  elsif dealer_total >= DEALER_MIN
    redirect '/game/compare_hands'
  else
    @show_dealer_hit_button = true
  end
  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_hand] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare_hands' do
  @show_hit_or_stay_buttons = false

  player_total = calculate_total(session[:player_hand])
  dealer_total = calculate_total(session[:dealer_hand])

  if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  else
    tie!("Both #{session[:player_name]} and the dealer stayed at #{player_total}.")
  end
  erb :game
end

get '/game_over' do
  erb :game_over
end
