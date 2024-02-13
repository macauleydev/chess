require_relative 'board'
module Move # rubocop:disable Style/Documentation,Metrics/ModuleLength
  def make_move(from_square, to_square)
    # assumed: move is valid
    captured_square = if occupied?(to_square)
                        to_square
                      elsif valid_en_passant?(from_square, to_square)
                        square_name(file_index(to_square),
                                    rank_index(to_square,
                                               increase: -1, color: color_at(from_square)))
                      end

    p record_move(from_square, to_square, captured_square:)
    make_capture_at(captured_square) if captured_square
    move_piece(from_square, to_square)
  end

  def move_piece(from_square, to_square)
    piece = piece_at(from_square)
    @squares[to_square] = piece if to_square
    piece.square = to_square
    @squares[from_square] = nil
  end

  def remove_piece(from_square)
    move_piece(from_square, nil)
  end

  def make_capture_at(captured_square)
    record_capture_at(captured_square)
    remove_piece(captured_square)
  end

  def record_move(from_square, to_square, captured_square: nil)
    piece_type = piece_type_at(from_square)
    captured_piece_type = piece_type_at(captured_square) if captured_square
    @moves << { from_square:, to_square:, piece_type:, captured_square:, captured_piece_type: }
  end

  def record_capture_at(captured_square)
    @captures << piece_at(captured_square)
  end

  def valid_move?(from_square, to_square) # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/AbcSize
    # assumed: both squares are on the board; from_square is correct color
    piece = piece_at(from_square)
    return false if to_square == from_square
    return valid_attack?(from_square, to_square) unless empty_square?(to_square)

    case piece
    in Pawn
      case file_shift(from_square, to_square).abs
      when 1
        valid_en_passant?(from_square, to_square) if rank_would_grow(from_square, to_square) == 1
      when 0
        steps = rank_would_grow(from_square, to_square)
        allowed_steps = [1]
        allowed_steps << 2 if piece.unmoved?
        allowed_steps.include?(steps)
      else false
      end
    in Bishop
      file_shift(from_square, to_square).abs == rank_would_grow(from_square, to_square)
    else
      false
    end
  end

  def valid_attack?(from_square, to_square)
    moving_piece = piece_at(from_square)
    case moving_piece
    in Pawn
      file_shift(from_square, to_square).abs == 1 && rank_would_grow(from_square, to_square) == 1
    in Bishop
      file_shift(from_square, to_square).abs == rank_would_grow(from_square, to_square)
    else
      false
    end
  end

  def valid_en_passant?(from_square, to_square) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    captured_square = square_name(file_index(to_square),
                                  rank_index(to_square,
                                             increase: -1, color: color_at(from_square)))

    if empty_square?(captured_square)
      invalid_reason = 'the square you would capture is empty.'
    elsif color_at(from_square) == color_at(captured_square)
      invalid_reason = 'the square you would capture is your own color.'
    elsif @moves&.last&.[](:to_square) != captured_square
      invalid_reason = "the square you would capture wasn't the last move's target."
    elsif @moves&.last&.[](:piece_type) != Pawn
      invalid_reason = "the last piece moved wasn't a Pawn."
    elsif rank_grew(@moves&.last&.[](:from_square), @moves&.last&.[](:to_square)) != 2
      invalid_reason = "the last move wasn't from two ranks behind the target square."
    else
      return true
    end

    puts "Invalid En Passant because #{invalid_reason}"
    false
  end

  def rank_would_grow(from_square, to_square)
    rank_growth(from_square, to_square, color: piece_at(from_square).color)
  end

  def rank_grew(from_square, to_square)
    rank_growth(from_square, to_square, color: piece_at(to_square).color)
  end

  private

  def rank_growth(from_square, to_square, color: nil)
    return unless a_square?(from_square) && a_square?(to_square)

    direction = color ? color.direction : 1
    from_rank, to_rank = [from_square, to_square].map { rank_number(_1) }
    (to_rank - from_rank) * direction
  end

  def file_shift(from_square, to_square)
    return unless a_square?(from_square) && a_square?(to_square)

    from_file, to_file = [from_square, to_square].map { file_index(_1) }
    to_file - from_file
  end
end
