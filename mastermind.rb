# frozen_string_literal: true

module Display
  def colour(colour_code)
    {
      '1' => "\x1b[42m 1 \x1b[0m",
      '2' => "\x1b[43m 2 \x1b[0m",
      '3' => "\x1b[44m 3 \x1b[0m",
      '4' => "\x1b[45m 4 \x1b[0m",
      '5' => "\x1b[46m 5 \x1b[0m",
      'red' => "\x1b[41m   \x1b[0m",
      'white' => "\x1b[47m   \x1b[0m"
    }[colour_code]
  end

  def show_colour_options
    ('1'..'5').each do |num|
      print colour(num)
    end
  end

  def show_previous_guesses
    previous_guesses.each do |guess|
      guess[0].each do |num|
        print colour(num)
      end
      guess[1][0].times { print " #{colour('red')}" }
      guess[1][1].times { print " #{colour('white')}" }
      puts "\n\n"
    end
  end
end

module TextContent
  def instructions
    puts "\nThese are the instructions for mastermind.\n"
  end

  def welcome_message
    puts "\nWelcome to mastermind!"
  end

  def choose_mode
    puts "Would you like to be the maker[1] or the breaker[2]?\n'1' or '2'\n"
    gets.chomp
  end

  def enter_guess_message
    puts "\nEnter your guess! It must only be 4 digits without any spaces in between:"
  end

  def enter_code_message
    puts 'Enter the secret code for the computer to solve! It must only be 4 digits without any spaces in between:'
  end

  def colour_options_message
    puts "\n\nThese are your colour options:"
  end

  def created_new_game
    puts 'A new game has been created.'
  end

  def solved_message
    puts "The computer solved your code in #{previous_guesses.length} turns."
  end

  def win_message
    puts 'You won the game!'
  end

  def loose_message
    puts 'You lost the game!'
  end
end

class GameMode
  attr_accessor :secret_code, :previous_guesses

  include Display
  include TextContent

  def initialize
    @previous_guesses = []
  end

  def get_input
    gets.chomp.split('')
  end

  def submit_guess(guess)
    exact_and_colour_match = compare(guess)
    add_guess(guess, exact_and_colour_match)
  end

  def compare(guess, code = secret_code)
    no_exact_matches_guess = []
    no_exact_matches_code = []
    exact_and_colour_match = [0, 0]
    4.times do |i|
      if guess[i] == code[i]
        exact_and_colour_match[0] += 1
      else
        no_exact_matches_code.push(code[i])
        no_exact_matches_guess.push(guess[i])
      end
    end
    no_exact_matches_code.each do |colour|
      if (guess_idx = no_exact_matches_guess.index(colour))
        exact_and_colour_match[1] += 1
        no_exact_matches_guess.delete_at(guess_idx)
      end
    end
    exact_and_colour_match
  end

  def add_guess(checked_guess, exact_and_colour_match)
    previous_guesses.push([checked_guess, exact_and_colour_match])
  end

  def check_win
    previous_guesses.last[1][0] == 4
  end

  def enter_input(type)
    colour_options_message
    show_colour_options
    loop do
      type == 'guess' ? enter_guess_message : enter_code_message
      input = get_input
      break input if check_input(input)
    end
  end

  def check_input(input)
    input.length == 4 && input.all? { |num| ('1'..'5').include?(num) }
  end

  def check_loose
    true if previous_guesses.length >= 12
  end
end

class HumanSolver < GameMode
  def initialize
    super
    @secret_code = Array.new(4) { rand(1..5).to_s }
  end

  def turn
    checked_guess = enter_input('guess')
    submit_guess(checked_guess)
    show_previous_guesses
  end
end

class ComputerSolver < GameMode
  attr_accessor :s, :unused, :secret_code

  POSSIBLE_RESULTS = [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4], [1, 0], [1, 1], [1, 2], [1, 3], [2, 0], [2, 1], [2, 2], [3, 0],
                      [3, 1], [4, 0]].freeze

  def initialize
    super
    @s = ('1'..'5').to_a.repeated_permutation(4).to_set
    @unused = @s.clone
    @secret_code = ''
  end

  def set_secret_code
    self.secret_code = enter_input('secret_code')
  end

  def count_eliminations(guess, result)
    s.count do |code|
      result != compare(guess, code)
    end
  end

  def find_next_guess
    eval_unused = unused.map do |guess|
      eliminations_array = POSSIBLE_RESULTS.map do |result|
        count_eliminations(guess, result)
      end
      score = eliminations_array.min
      [guess, score]
    end
    highest_score = eval_unused.max { |guess1, guess2| guess1[1] <=> guess2[1] }[1]
    highest_guess_scores_array = eval_unused.find_all { |guess| guess[1] == highest_score }
    (highest_guess_scores_array.find { |guess| s.include?(guess[0]) } || highest_guess_scores_array.first)[0]
  end

  def delete_impossible_codes(exact_and_colour_match, guess)
    s.delete_if do |code|
      exact_and_colour_match != compare(guess, code)
    end
  end

  def solve
    guess = %w[1 1 2 2]
    submit_guess(guess)
    until check_win
      s.delete(guess)
      unused.delete(guess)
      delete_impossible_codes(previous_guesses.last[1], guess)
      guess = find_next_guess
      submit_guess(guess)
    end
  end
end

class Game
  include TextContent

  def play
    welcome_message
    instructions
    mode = loop do
      mode = choose_mode.chomp
      break mode if %w[1 2].include?(mode)
    end
    if mode == '1'
      player = HumanSolver.new
      loop do
        player.turn
        if player.check_win
          player.win_message
          break
        end
        if player.check_loose
          player.loose_message
          break
        end
      end
    elsif mode == '2'
      computer = ComputerSolver.new
      enter_code_message
      computer.set_secret_code
      computer.solve
      computer.show_previous_guesses
      computer.solved_message
    end
  end
end

new_game = Game.new
new_game.play
# p new_game.compare(%w[1 2 3 3])
# p new_game.secret_code
# puts newGame.show_colour_options
