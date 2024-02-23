require_relative "board"
require_relative "color"
require_relative "move"
require_relative "piece"
require_relative "player"
require "json"

class Game
  def initialize(board = Board.new)
    @board = board
    @show_help = true
  end

  def play
    introduce_game
    play_game
  end

  def introduce_game
    @board.labels_hidden = true
    show_board
    @board.labels_hidden = false
    puts "Welcome to Terminal Chess! (powered by Ruby)"
    gets
    puts "If the chess pieces are hard to see, please find\nyour keyboard's Cmd (Mac) or Ctrl (Windows/Linux) key,\nthen hold it while pressing = (+) or - to zoom in or out."
    gets
    puts "Currently, both sides must be played by a human."
    puts "Ready to play?"
    gets
  end

  def play_game
    loop do
      from, to = get_valid_move
      perform_move(from, to)

      if checkmate?
        show_board
        puts "Checkmate!"
        break
      elsif draw?
        show_board
        puts "Draw."
        break
      end
    end
  end

  def perform_move(from, to)
    duration = 0.1
    show_board(active_squares: [from], duration:)
    show_board(active_squares: [from, to] + @board.squares_between(from, to), duration:)

    @board.make_move(from, to)

    show_board(active_squares: [from, to], duration: duration)
    show_board(active_squares: [to], duration:)
  end

  def get_valid_move
    loop do
      # from, to = @board.moves&.last&.[](:from_square), @board.moves&.last&.[](:to_square)
      # show_board(active_squares: [from, to])
      show_board
      puts "Check!" if check?
      if @show_help || @board.moves.count.zero?
        entry_hint = "\nEnter move as coordinates (b1c3) or\nin minimal algebraic notation (Nc3).\nOr, type a command: save, load, ?\n"
        @show_help = false
      else
        entry_hint = "\nEnter move, or ? for help.\n"
      end
      puts faded(entry_hint)
      print("#{@board.player.name}'s move: ")
      input = gets.chomp
      case input
      when "?"
        @show_help = true
        next
      when "save"
        save_and_exit
      when "load"
        load_game
      end
      return coordinates(input) if coordinates(input) && @board.valid_move?(*coordinates(input))
    end
  end

  def save_and_exit
    puts self
    saved_game = self
    filename = "saved_game.pgn"
    File.open(filename, "w") do |file|
      file.puts saved_game
    end
    puts "Game saved."
    exit
  end

  def load_game
    filename = "saved_game.pgn"
    pgn_game = File.read(filename)
    moves = pgn_to_minimal_algebraic(pgn_game)
    initialize
    moves.each do |move|
      from, to = coordinates(move)
      # validate
      perform_move(from, to)
    end
    play_game
  end

  def pgn_to_minimal_algebraic(pgn_game)
    words = pgn_game.split
    moves = words.filter do |move| # strip move numbers & spaced e.p. indicator
      patterns = [/(\d)+\./, /e\.p\./]
      patterns.none? { |regex| move.match?(regex) }
    end
    moves.map do |move| # strip capture, check(mate), and unspaced e.p. indicators
      move.gsub(/x|\+|\#|e\.p\./, "")
    end
  end

  def check?
    @board.moves&.last&.[](:check)
  end

  def checkmate?
    @board.moves&.last&.[](:checkmate)
  end

  def draw?
    @board.moves&.last&.[](:draw)
  end

  def show_board(active_squares: [], duration: 0)
    system("clear") || system("cls")
    puts "#{to_s(color: true)}\n\n"
    puts @board.to_s(active_squares:)
    sleep(duration)
  end

  def coordinates(move_string, board: @board)
    # Accepted formats: coordinates (b1c3) or minimal algebraic (Nc3)
    raise "Invalid input, #{move_string}: must be a string" unless move_string.is_a?(String)

    chars = move_string.chars
    to_square = chars.pop(2).join
    return nil if !board.square?(to_square) || chars.count > 3

    if board.square?(chars.last(2).join)
      from_square = chars.pop(2).join
      return nil if chars.count > 1

      if chars.count == 1
        specified_piece_key = chars.first.upcase
        actual_piece_key = board.contents[from_square]&.key
        return nil unless specified_piece_key == actual_piece_key
      end
    elsif chars.count.zero?
      pawn_squares = board.squares_of(color: board.player.color, type: Pawn)
      valid_from_squares = pawn_squares.filter do |pawn_square|
        board.valid_move?(pawn_square, to_square)
      end
      from_square = valid_from_squares.one? ? valid_from_squares.first : nil
    elsif chars.count == 1
      if Board::FILE_LETTERS.include?(specified_file_letter = chars.first)
        pawn_squares = board.squares_of(color: board.player.color, type: Pawn)
        from_squares = pawn_squares.filter do |pawn_square|
          actual_file_letter = board.file_letter(pawn_square)
          board.valid_move?(pawn_square, to_square) &&
            specified_file_letter == actual_file_letter
        end
        from_square = from_squares.one? ? from_squares.first : nil
      end
      if from_square.nil?
        specified_piece_key = chars.first.upcase
        from_squares = board.squares_of(color: board.player.color)
        valid_from_squares = from_squares.filter do |from_square|
          board.valid_move?(from_square, to_square)
        end
        matching_from_squares = valid_from_squares.filter do |from_square|
          actual_piece_key = board.contents[from_square]&.key
          specified_piece_key == actual_piece_key
        end
        puts "Matching from squares: #{matching_from_squares}"
        from_square = matching_from_squares.one? ? matching_from_squares.first : nil
      end
    elsif chars.count == 2
      specified_piece_key = chars.first.upcase
      from_squares = board.squares_of(color: board.player.color)
      valid_from_squares = from_squares.filter do |from_square|
        board.valid_move?(from_square, to_square)
      end

      if Board::FILE_LETTERS.include?(specified_file_letter = chars.last)
        matching_from_squares = valid_from_squares.filter do |from_square|
          actual_file_letter = board.file_letter(from_square)
          specified_file_letter == actual_file_letter
        end
      elsif Board::RANK_NAMES.include?(specified_rank_name = chars.last)
        matching_from_squares = valid_from_squares.filter do |from_square|
          actual_rank_name = board.rank_name(from_square)
          specified_rank_name == actual_rank_name
        end
      end
      from_square = matching_from_squares.one? ? matching_from_squares.first : nil
    else
      return nil
    end
    # puts "Coordinates parsed as: [#{from_square}, #{to_square}]"
    [from_square, to_square] if from_square
  end

  def to_s(color: false)
    game_notation = @board.moves.each_with_index.reduce("") do |game, (move, index)|
      if index.even?
        # newline = "\n" if index.positive?
        newline = ""
        move_pair_number = "#{newline}#{(index / 2) + 1}. "
        if color && @board.moves.length - index > 2
          move_pair_number = faded(move_pair_number)
        end
      end
      piece =
        case move[:piece]
        in Pawn
          move[:capture] ? @board.file_letter(move[:from_square]) : ""
        else
          move[:piece].key
        end
      to_square = move[:to_square]
      capture = move[:capture] ? "x" : ""
      en_passant = move[:en_passant] ? " e.p." : ""
      check = move[:check] ? "+" : nil
      checkmate = move[:checkmate] ? "#" : nil
      move = "#{piece}#{capture}#{to_square}#{en_passant}#{check || checkmate}"
      if color && index + 1 != @board.moves.length
        move = faded(move)
      end
      # move += "\n" if index.odd?
      game + "#{move_pair_number || ""}#{move} "
    end
    game_notation.strip
  end

  def fg_faded
    @board.fg_faded
  end

  def faded(string)
    Paint[string, fg_faded]
  end
end
