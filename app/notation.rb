require_relative "grid"

module Notation
  include Grid
  def to_s(highlight: true)
    game_notation = @board.moves.each_with_index.reduce("") do |game, (move, index)|
      if index.even?
        # newline = "\n" if index.positive?
        newline = ""
        move_pair_number = "#{newline}#{(index / 2) + 1}. "
        if highlight && @board.moves.length - index > 2
          move_pair_number = faded(move_pair_number)
        end
      end
      piece =
        if move[:piece].is_a?(Pawn)
          move[:capture] ? file_letter(move[:from_square]) : ""
        else
          move[:piece].key
        end
      to_square = move[:to_square]
      capture = move[:capture] ? "x" : ""
      en_passant = move[:en_passant] ? " e.p." : ""
      check = move[:check] ? "+" : nil
      checkmate = move[:checkmate] ? "#" : nil
      move = "#{piece}#{capture}#{to_square}#{en_passant}#{check || checkmate}"
      if highlight && index + 1 != @board.moves.length
        move = faded(move)
      end
      # move += "\n" if index.odd?
      game + "#{move_pair_number || ""}#{move} "
    end
    game_notation.strip
  end

  def movement(move_string, board: @board)
    # Accepted formats: coordinates (b1c3) or minimal algebraic (Nc3)
    raise "Invalid input, #{move_string}: must be a string" unless move_string.is_a?(String)
    chars = move_string.chars
    to_square = chars.pop(2).join
    return nil if !square?(to_square) || chars.count > 3

    if square?(chars.last(2).join)
      from_square = chars.pop(2).join
      return nil if chars.count > 1

      if chars.count == 1
        specified_piece_key = chars.first.upcase
        actual_piece_key = board.contents[from_square]&.key
        return nil unless specified_piece_key == actual_piece_key
      end
    elsif chars.count.zero?
      pawn_squares = board.squares_of(color: board.player.color, type: Pawn)
      legal_from_squares = pawn_squares.filter do |pawn_square|
        board.legal_move?(pawn_square, to_square)
      end
      from_square = legal_from_squares.one? ? legal_from_squares.first : nil
    elsif chars.count == 1
      if FILE_LETTERS.include?(specified_file_letter = chars.first)
        pawn_squares = board.squares_of(color: board.player.color, type: Pawn)
        from_squares = pawn_squares.filter do |pawn_square|
          actual_file_letter = file_letter(pawn_square)
          board.legal_move?(pawn_square, to_square) &&
            specified_file_letter == actual_file_letter
        end
        from_square = from_squares.one? ? from_squares.first : nil
      end
      if from_square.nil?
        specified_piece_key = chars.first.upcase
        from_squares = board.squares_of(color: board.player.color)
        legal_from_squares = from_squares.filter do |from_square|
          board.legal_move?(from_square, to_square)
        end
        matching_from_squares = legal_from_squares.filter do |from_square|
          actual_piece_key = board.contents[from_square]&.key
          specified_piece_key == actual_piece_key
        end
        from_square = matching_from_squares.one? ? matching_from_squares.first : nil
      end
    elsif chars.count == 2
      specified_piece_key = chars.first.upcase
      from_squares = board.squares_of(color: board.player.color)
      legal_from_squares = from_squares.filter do |from_square|
        board.legal_move?(from_square, to_square)
      end

      if FILE_LETTERS.include?(specified_file_letter = chars.last)
        matching_from_squares = legal_from_squares.filter do |from_square|
          actual_file_letter = file_letter(from_square)
          specified_file_letter == actual_file_letter
        end
      elsif RANK_NAMES.include?(specified_rank_name = chars.last)
        matching_from_squares = legal_from_squares.filter do |from_square|
          actual_rank_name = rank_name(from_square)
          specified_rank_name == actual_rank_name
        end
      end
      from_square = matching_from_squares.one? ? matching_from_squares.first : nil
    else
      return nil
    end
    [from_square, to_square] if from_square
  end

  def load_game_and_play
    filename = "saved_game.pgn"
    pgn_game = File.read(filename)
    move_strings = pgn_to_minimal_algebraic(pgn_game)
    initialize
    move_strings.each do |move_string|
      from, to = movement(move_string)
      perform_move(from, to)
    end
    play(skip_intro: true)
  end

  private

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

  def save_game_and_exit
    saved_game = to_s(highlight: false)
    filename = "saved_game.pgn"
    File.open(filename, "w") do |file|
      file.puts saved_game
    end
    puts "Game saved."
    exit
  end
end
