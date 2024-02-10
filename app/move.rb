require_relative 'board'
module Move # rubocop:disable Style/Documentation
  def move_piece(from_square, to_square)
    # assumed: move is valid
    moving_piece = squares[from_square]
    moving_piece.square = to_square
    squares[to_square] = moving_piece
    squares[from_square] = nil
  end

  def valid_move?(from_square, to_square) # rubocop:disable Metrics/MethodLength
    # assumed: both squares are on the board; from_square is correct color
    moving_piece = square(from_square)
    return valid_attack?(from_square, to_square) unless available?(to_square)

    case moving_piece
    in Pawn
      return false unless file_shift(from_square, to_square).zero?

      steps = rank_increase(from_square, to_square)
      allowed_steps = [1]
      allowed_steps << 2 if moving_piece.unmoved?
      allowed_steps.include?(steps)
    else
      false
    end
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

  def rank_increase(from_square, to_square, color = square(from_square).color)
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
