require_relative 'board'
module Move # rubocop:disable Style/Documentation
  def make_move(from_square, to_square) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    # assumed: move is valid
    moving_piece = squares[from_square]
    captured_piece = square(to_square)

    if captured_piece
      capture(to_square)
    elsif en_passant?(from_square, to_square)
      passant_captured_square = square_name(file_index(to_square),
                                            rank_index(to_square,
                                                       increase: -1, color: from_square.color))
      capture(passant_captured_square)
    end

    squares[to_square] = moving_piece
    moving_piece.square = to_square
    squares[from_square] = nil

    p last_moving_piece
    p record_move(moving_piece.class, from_square, to_square, captured_piece_type: captured_piece&.class)
    p last_moving_piece
  end

  def record_move(piece_type, from_square, to_square, captured_piece_type: nil,
                  captured_square: captured_piece_type ? to_square : nil)
    @moves << { piece_type:, from_square:, to_square:, captured_piece_type:, captured_square: }
  end

  def valid_move?(from_square, to_square) # rubocop:disable Metrics/MethodLength
    # assumed: both squares are on the board; from_square is correct color
    moving_piece = square(from_square)
    return valid_attack?(from_square, to_square) unless available?(to_square)

    case moving_piece
    in Pawn
      case file_shift(from_square, to_square).abs
      when 1 then en_passant?(from_square, to_square)
      when 0
        steps = rank_increase(from_square, to_square)
        allowed_steps = [1]
        allowed_steps << 2 if moving_piece.unmoved?
        allowed_steps.include?(steps)
      else false
      end
    else
      false
    end
  end

  def en_passant?(from_square, to_square) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    ############### RESUME HERE (troubleshoot) ###########################
    captured_square = square_name(file_index(to_square),
                                  rank_index(to_square,
                                             increase: -1, color: square(from_square).color))
    captured_piece = square(captured_square)
    return false unless occupied?(captured_square)

    attacking_piece = square(from_square)
    return false if captured_piece.color == attacking_piece.color

    return false unless rank_index(from_square) == 4

    captured_piece.instance_of?(Pawn) &&
      last_moving_piece == captured_piece &&
      captured_piece.squares_visited.length == 2
  end

  def valid_attack?(from_square, to_square)
    moving_piece = square(from_square)
    case moving_piece
    in Pawn
      file_shift(from_square, to_square).abs == 1 && rank_increase(from_square, to_square) == 1
    else
      false
    end
  end

  def rank_increase(from_square, to_square, color: square(from_square).color)
    return unless a_square?(from_square) && a_square?(to_square)

    direction = color.direction
    from_rank, to_rank = [from_square, to_square].map { rank_number(_1) }
    (to_rank - from_rank) * direction
  end

  def file_shift(from_square, to_square)
    return unless a_square?(from_square) && a_square?(to_square)

    from_file, to_file = [from_square, to_square].map { file_index(_1) }
    to_file - from_file
  end
end
