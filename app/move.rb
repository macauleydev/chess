require_relative 'board'
module Move # rubocop:disable Style/Documentation,Metrics/ModuleLength
  FILE_STEPS = [1, -1].product([0])
  RANK_STEPS = [0].product([1, -1])
  STRAIGHT_STEPS = FILE_STEPS + RANK_STEPS
  DIAGONAL_STEPS = [1, -1].product([1, -1])
  ALL_STEPS = STRAIGHT_STEPS + DIAGONAL_STEPS
  KNIGHT_LEAPS = [1, -1].product([2, -2]) + [2, -2].product([1, -1])

  def make_move(from_square, to_square)
    # assumed: move is valid
    captured_square = if occupied?(to_square)
                        to_square
                      elsif en_passant?(from_square, to_square)
                        square_at(file_index(to_square),
                                  rank_index(to_square,
                                             increase: -1, color: color_on(from_square)))
                      end

    record_move(from_square, to_square, captured_square:)
    make_capture_at(captured_square) if captured_square
    move_piece(from_square, to_square)
  end

  def move_piece(from_square, to_square)
    piece = @contents[from_square]
    @contents[to_square] = piece if to_square
    piece.square = to_square
    @contents[from_square] = nil
  end

  def remove_piece(from_square)
    move_piece(from_square, nil)
  end

  def make_capture_at(captured_square)
    record_capture_at(captured_square)
    remove_piece(captured_square)
  end

  def record_move(from_square, to_square, captured_square: nil, check: nil)
    piece_type = piece_type_on(from_square)
    captured_piece_type = piece_type_on(captured_square) if captured_square
    check = true if check?
    @moves << { from_square:, to_square:, piece_type:, captured_square:, captured_piece_type:, check: }
  end

  def record_capture_at(captured_square)
    @captures << @contents[captured_square]
  end

  def valid_move?(from_square, to_square) # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/AbcSize,Metrics/PerceivedComplexity
    # assumed: both squares are on the board; from_square is correct color
    piece = @contents[from_square]
    return false if color_on(to_square) == color_on(from_square)
    return valid_attack?(from_square, to_square) unless square_empty?(to_square)

    case piece
    when Pawn
      case file_shift(from_square, to_square).abs
      when 1
        en_passant?(from_square, to_square) if rank_would_grow(from_square, to_square) == 1
      when 0
        steps = rank_would_grow(from_square, to_square)
        allowed_steps = [1]
        allowed_steps << 2 if piece.unmoved?
        allowed_steps.include?(steps) &&
          empty_between?(from_square, to_square)
      else false
      end
    when Bishop
      diagonal?(from_square, to_square) &&
        empty_between?(from_square, to_square)
    when Rook
      straight?(from_square, to_square) &&
        empty_between?(from_square, to_square)
    when Queen
      (straight?(from_square, to_square) || diagonal?(from_square, to_square)) &&
        empty_between?(from_square, to_square)
    when King
      adjacent?(from_square, to_square)
    when Knight
      knight_leap?(from_square, to_square)
    else
      false
    end
  end

  def valid_attack?(from_square, to_square) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
    case @contents[from_square]
    when Pawn
      file_shift(from_square, to_square).abs == 1 && rank_would_grow(from_square, to_square) == 1
    when Bishop
      diagonal?(from_square, to_square) &&
        empty_between?(from_square, to_square)
    when Rook
      straight?(from_square, to_square) &&
        empty_between?(from_square, to_square)
    when Queen
      (straight?(from_square, to_square) || diagonal?(from_square, to_square)) &&
        empty_between?(from_square, to_square)
    when King
      adjacent?(from_square, to_square)
    when Knight
      knight_leap?(from_square, to_square)
    else
      false
    end
  end

  def en_passant?(from_square, to_square) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    captured_square = square_at(file_index(to_square),
                                rank_index(to_square,
                                           increase: -1, color: color_on(from_square)))

    if square_empty?(captured_square)
      invalid_reason = 'the square you would capture is empty.'
    elsif color_on(from_square) == color_on(captured_square)
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

    # puts "Invalid En Passant because #{invalid_reason}"
    false
  end

  def rank_would_grow(from_square, to_square)
    rank_growth(from_square, to_square, color: color_on(from_square))
  end

  def rank_grew(from_square, to_square)
    rank_growth(from_square, to_square, color: color_on(to_square))
  end

  def file_rank_would_change(from_square, to_square)
    [file_shift(from_square, to_square),
     rank_would_grow(from_square, to_square)]
  end

  def diagonal?(from_square, to_square)
    file_rank_would_change(from_square, to_square).map(&:abs) in [1..7 => _n, ^_n]
  end

  def straight?(from_square, to_square)
    [file_shift(from_square, to_square), rank_would_grow(from_square, to_square)].one?(0)
  end

  def adjacent?(from_square, to_square)
    ALL_STEPS.include?(file_rank_would_change(from_square, to_square))
  end

  def knight_leap?(from_square, to_square)
    KNIGHT_LEAPS.include?(file_rank_would_change(from_square, to_square))
  end

  private

  def rank_growth(from_square, to_square, color: nil)
    return unless square?(from_square) && square?(to_square)

    direction = color ? color.direction : 1
    from_rank, to_rank = [from_square, to_square].map { rank_number(_1) }
    (to_rank - from_rank) * direction
  end

  def file_shift(from_square, to_square)
    return unless square?(from_square) && square?(to_square)

    from_file, to_file = [from_square, to_square].map { file_index(_1) }
    to_file - from_file
  end
end
