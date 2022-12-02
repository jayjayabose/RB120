class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows,
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # columns,
                  [[1, 5, 9], [7, 5, 3]] # diagonals

  def initialize
    @squares = {}
    reset
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def draw
    puts "     |     |     "
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}  "
    puts "     |     |     "
    puts " ----+-----+-----"
    puts "     |     |     "
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}  "
    puts "     |     |     "
    puts " ----+-----+-----"
    puts "     |     |     "
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}  "
    puts "     |     |     "
    puts ""
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def []=(key, marker)
    @squares[key].marker = marker
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def middle_unmarked?
    @squares[5].unmarked?
  end  

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if three_identical_markers?(squares)
        return squares.first.marker
      end
    end
    nil
  end

  def high_value_key(marker)
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      high_value_line = squares.count { |s| s.marker == marker } == 2
      if high_value_line
        line.each do |key|
          return key if @squares[key].unmarked?
        end
      end
    end
    nil
  end

  private

  def three_identical_markers?(squares)
    marks = squares.reject(&:unmarked?).collect(&:marker)
    return false if marks.count != 3
    marks.uniq.count == 1
  end
end

class Square
  INITIAL_MARKER = ' '

  attr_accessor :marker

  def initialize(marker = INITIAL_MARKER)
    @marker = marker
  end

  def unmarked?
    @marker == INITIAL_MARKER
  end

  def to_s
    @marker
  end  
end

class Player
  attr_reader :marker

  def initialize(marker)
    @marker = marker
  end
end

class TTTGame
  HUMAN_MARKER = 'X'
  COMPUTER_MARKER = '0'
  POINTS_TARGET = 3

  def play
    loop do # series loop
      display_welcome_message
      configure_game
      play_game until series_winner?
      display_series_end_message
      play_another_series? ? reset_points : break
    end
    display_goodbye_message
  end

  private

  attr_reader :board, :human, :computer
  attr_accessor :human_points, :computer_points, :current_marker, :difficult, :first_to_move

  def initialize
    @board = Board.new
    @human = Player.new(HUMAN_MARKER)
    @computer = Player.new(COMPUTER_MARKER)
    @human_points = 0
    @computer_points = 0
    @current_marker = nil
    @difficult = nil
    @first_to_move = nil
  end

  def configure_game
    self.first_to_move = human_plays_first? ? HUMAN_MARKER : COMPUTER_MARKER  #reverse this
    self.current_marker = first_to_move
    self.difficult = difficult_mode?
    puts "OK. We're ready to begin. Press 'enter' to continue."
    loop do
      gets
      break
    end
    clear
  end

  def play_game
    display_board
    do_player_moves
    display_result
    update_score
    reset_game
  end

  def do_player_moves
    loop do # repeat player moves until game is complete
      current_player_moves
      break if board.someone_won? || board.full?
      clear_screen_and_display_board if human_turn?
    end
  end

  # SECTION: Move Methods
  def human_moves
    puts "Choose a position to place your marker: #{joinor(board.unmarked_keys)}"
    square = nil
    loop do
      square = gets.chomp.to_i
      break if board.unmarked_keys.include? square
      puts "Sorry, that's not a valid choice."
    end

    board[square] = human.marker
  end

  def computer_moves
    key = if difficult && find_offensive_key
            find_offensive_key
          elsif difficult && find_defensive_key
            find_defensive_key
          elsif board.middle_unmarked?
            5
          else
            board.unmarked_keys.sample
          end
    board[key] = computer.marker
  end

  def find_defensive_key
    board.high_value_key(HUMAN_MARKER)
  end

  def find_offensive_key
    board.high_value_key(COMPUTER_MARKER)
  end

  def current_player_moves
    if human_turn?
      human_moves
      self.current_marker = COMPUTER_MARKER
    else
      computer_moves
      self.current_marker = HUMAN_MARKER
    end
  end

  def human_turn?
    self.current_marker == HUMAN_MARKER
  end

  # SECTION: Game Status Methods
  def update_score
    case board.winning_marker
    when HUMAN_MARKER then self.human_points += 1
    when COMPUTER_MARKER then self.computer_points += 1
    end
  end

  def reset_game
    board.reset
    alternate_first_move
    if series_winner?
      sleep 2 
      clear
    else
      clear if ready_to_continue?
    end    
  end

  def alternate_first_move
    self.first_to_move = first_to_move == HUMAN_MARKER ? COMPUTER_MARKER : HUMAN_MARKER
    self.current_marker = first_to_move
  end

  def series_winner?
    !!detect_series_winner
  end

  def detect_series_winner
    if computer_points == POINTS_TARGET
      COMPUTER_MARKER
    elsif human_points == POINTS_TARGET
      HUMAN_MARKER
    end
  end

  def reset_points
    self.human_points = 0
    self.computer_points = 0
  end

  # SECTION: User Inut Methods
  def human_plays_first?
    response = nil
    loop do
      puts "** Set First Player **"
      puts "Would you like to play first? Enter 'y' or 'n'"
      response = gets.chomp.downcase
      break if ['y', 'n', 'yes', 'no'].include? response
      puts "That was not a valid response"
    end
    response == 'y' || response == 'yes'
  end

  def difficult_mode?
    response = nil
    loop do
      puts "** Set Difficulty **"
      puts "Would you like to play easy or difficult mode? Enter 'e' or 'd'"
      response = gets.chomp.downcase[0]
      break if ['e', 'd', 'easy', 'difficult'].include? response
      puts "That was not a valid response"
    end
    response == 'd' || response == 'difficult'
  end

  def play_another_series?
    response = nil
    loop do
      puts "** Play again? **"
      puts "Would you like to play another series? Enter 'y' or 'n'"
      response = gets.chomp.downcase[0]
      break if ['y', 'n', 'yes', 'no'].include? response
      puts "That was not a valid response"
    end
    response == 'y' || response == 'yes'
  end

  def ready_to_continue?
    loop do
      puts "** Ready to continue the series? **"
      puts "Press 'return' to continue."
      gets
      break
    end
    true
  end

  # SECTION: Display Methods
  def display_welcome_message
    clear
    puts <<~MSG
    "Welcome to Tic Tac Toe!"

    MSG
  end

  def display_goodbye_message
    puts <<~MSG
    Thanks for playing Tic Tac Toe! Goodbye

    MSG
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def display_player_marks
    puts <<~MSG
    ** Player Marks **"
    You:      '#{TTTGame::HUMAN_MARKER}'
    Computer: '#{TTTGame::COMPUTER_MARKER}'

    MSG
  end

  def display_score
    puts <<~MSG
    ** Series Score **
    Human:     #{human_points}
    Computer:  #{computer_points}

    First player to #{POINTS_TARGET} wins the series

    MSG
  end

  def display_board
    display_score
    display_player_marks
    board.draw
    puts ""
  end

  def display_result
    clear_screen_and_display_board

    header =  "** Game Result **" + "\n"
    msg = case board.winning_marker
    when HUMAN_MARKER then "You win this game!"
    when COMPUTER_MARKER then "Computer wins this game."
    else  "The board is full -- tie game."
    end
    puts header + msg + "\n\n"
  end

  def display_series_end_message
    header = "** Series Result **" + "\n"
    msg = if detect_series_winner == HUMAN_MARKER
      "You won the series!"
    else
      "Computer won the series."
    end
    puts header + msg + "\n\n"
    display_score
  end

  def joinor(unmarked_squares, delimeter = ', ', conjunction = 'or')
    case unmarked_squares.count
    when 1 then unmarked_squares.first
    when 2 then "#{unmarked_squares.first} #{conjunction} #{unmarked_squares.last}"
    else
      left = unmarked_squares[0...-1].join(delimeter)
      right = "#{delimeter}#{conjunction} #{unmarked_squares[-1]}"
      left + right
    end
  end

  def clear
    system "clear"
  end
end

game = TTTGame.new
game.play
