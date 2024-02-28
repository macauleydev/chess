require_relative "board"
module Move
  FILE_STEPS = [1, -1].product([0])
  RANK_STEPS = [0].product([1, -1])
  STRAIGHT_STEPS = FILE_STEPS + RANK_STEPS
  DIAGONAL_STEPS = [1, -1].product([1, -1])
  ALL_STEPS = STRAIGHT_STEPS + DIAGONAL_STEPS
  KNIGHT_LEAPS = [1, -1].product([2, -2]) + [2, -2].product([1, -1])

  def make_move(from_square, to_square)
    # assumed: move is legal
    capture_square =
      if occupied?(to_square)
        to_square
      elsif en_passant_attack?(from_square, to_square)
        en_passant_capture_square(from_square, to_square)
      end

    record_move(from_square, to_square, capture_square:) unless hypothetical?
    make_capture_on(capture_square) if capture_square
    relocate_piece(from_square, to_square)

    rotate_players unless hypothetical?
  end

  def record_move(from_square, to_square, capture_square: nil)
    movement = [from_square, to_square]
    piece = @contents[from_square]

    capture = !capture_square.nil?
    if capture
      captured_piece = @contents[capture_square]
      en_passant = capture_square != to_square
    end

    threatens = threatens_king?(from_square, to_square)
    traps = traps_king?(from_square, to_square)
    checkmate = threatens && traps
    check = threatens && !traps
    draw = traps && !threatens

    @moves << {from_square:, to_square:, movement:, piece:,
               capture:, captured_piece:, en_passant:,
               check:, checkmate:, draw:}
  end

  def relocate_piece(from_square, to_square)
    piece = @contents[from_square]

    piece.square = to_square # = nil if piece is captured/removed

    @contents[from_square] = nil
    @contents[to_square] = piece unless to_square.nil?
  end

  def make_capture_on(capture_square)
    record_capture_on(capture_square) unless hypothetical?
    clear_square(capture_square)
  end

  def clear_square(square)
    relocate_piece(square, nil)
  end

  def record_capture_on(capture_square)
    @captures << @contents[capture_square]
  end

  def threatens_king?(from_square, to_square)
    return false if hypothetical?

    moving_color = color_on(from_square)
    hypothetical_board = clone
    hypothetical_board.make_move(from_square, to_square)
    hypothetical_board.king_threatened?(color_opposing(moving_color))
  end

  def traps_king?(from_square, to_square)
    return false if hypothetical?

    moving_color = color_on(from_square)
    hypothetical_board = clone
    hypothetical_board.make_move(from_square, to_square)
    hypothetical_board.king_trapped?(color_opposing(moving_color))
  end

  def would_endanger_own_king?(from_square, to_square)
    return false if @contents[to_square] in King

    color = color_on(from_square)
    hypothetical_board = clone
    hypothetical_board.make_move(from_square, to_square)
    hypothetical_board.king_threatened?(color)
  end

  def legal_move?(from_square, to_square)
    conceivable_move?(from_square, to_square) && !would_endanger_own_king?(from_square, to_square)
    # return false if path_blocked?(from_square, to_square)
  end

  def legal_move_by_color?(from_square, to_square, color)
    legal_move?(from_square, to_square) if color == color_on(from_square)
  end

  def conceivable_move?(from_square, to_square)
    # Conceivable: reachable (even if it would endanger king)
    conceivable_general_move?(from_square, to_square) &&
      conceivable_specific_move?(from_square, to_square)
  end

  def conceivable_general_move?(from_square, to_square)
    return false unless occupied?(from_square) && square?(to_square)
    return false if compatriot_squares?(from_square, to_square)

    true
  end

  def conceivable_specific_move?(from_square, to_square)
    piece = @contents[from_square]
    case piece
    when Pawn then conceivable_pawn_move?(from_square, to_square)
    when Bishop then conceivable_bishop_move?(from_square, to_square)
    when Rook then conceivable_rook_move?(from_square, to_square)
    when Queen then conceivable_queen_move?(from_square, to_square)
    when King then conceivable_king_move?(from_square, to_square)
    when Knight then conceivable_knight_move?(from_square, to_square)
    else
      raise "Piece is of an unrecognized type."
    end
  end

  def conceivable_pawn_move?(pawn_square, to_square)
    forward_steps = forward_steps(pawn_square, to_square)
    side_steps = side_steps(pawn_square, to_square)
    piece = @contents[pawn_square]

    if side_steps == 1 && forward_steps == 1
      occupied?(to_square) || en_passant_attack?(pawn_square, to_square)
    elsif side_steps == 0 && forward_steps == 1
      unoccupied?(to_square)
    elsif side_steps == 0 && forward_steps == 2
      piece.unmoved? &&
        unoccupied?(to_square) &&
        path_clear?(pawn_square, to_square)
    else
      false
    end
  end

  def conceivable_bishop_move?(bishop_square, to_square)
    diagonal?(bishop_square, to_square) && path_clear?(bishop_square, to_square)
  end

  def conceivable_rook_move?(rook_square, to_square)
    straight?(rook_square, to_square) && path_clear?(rook_square, to_square)
  end

  def conceivable_queen_move?(queen_square, to_square)
    (straight?(queen_square, to_square) || diagonal?(queen_square, to_square)) &&
      path_clear?(queen_square, to_square)
  end

  def conceivable_king_move?(king_square, to_square)
    adjacent?(king_square, to_square)
  end

  def conceivable_knight_move?(knight_square, to_square)
    knight_leap?(knight_square, to_square)
  end

  def en_passant_attack?(attack_from_square, attack_to_square)
    defense_color = color_opposing(color_on(attack_from_square))

    defense_square_passed_over = attack_to_square
    defense_square_passed_from = square_forward(defense_square_passed_over, -1, defense_color)
    defense_square_passed_to = square_forward(defense_square_passed_over, 1, defense_color)

    defense_passing_movement = [defense_square_passed_from, defense_square_passed_to]
    defense_passing_pawn = @contents[defense_square_passed_to]

    last_movement == defense_passing_movement &&
      defense_passing_pawn.is_a?(Pawn) &&
      defense_passing_pawn.color == defense_color
  end

  def file_rank_growth(from_square, to_square)
    [file_shift(from_square, to_square),
      rank_growth(from_square, to_square)]
  end

  def forward_steps(from_square, to_square)
    rank_growth(from_square, to_square)
  end

  def side_steps(from_square, to_square)
    file_shift(from_square, to_square).abs
  end

  def diagonal?(from_square, to_square)
    file_rank_growth(from_square, to_square).map(&:abs) in [1..7 => _n, ^_n]
  end

  def straight?(from_square, to_square)
    [forward_steps(from_square, to_square), side_steps(from_square, to_square)].one?(0)
  end

  def adjacent?(from_square, to_square)
    ALL_STEPS.include?(file_rank_growth(from_square, to_square))
  end

  def knight_leap?(from_square, to_square)
    KNIGHT_LEAPS.include?(file_rank_growth(from_square, to_square))
  end

  def legal_moves(color: player.color)
    conceivable_moves(color).filter do |from_square, to_square|
      !would_endanger_own_king?(from_square, to_square)
    end
  end

  def conceivable_moves(color: player.color)
    # Conceivable: reachable (even if it would endanger king)
    from_squares = squares_of(color:)
    from_squares.reduce([]) do |collected_moves, from_square|
      to_squares = reachable_squares(from_square)
      collected_moves + [from_square].product(to_squares)
    end
  end

  private

  def rank_growth(from_square, to_square)
    return unless square?(from_square) && square?(to_square)

    direction = color_on(from_square).direction
    from_rank, to_rank = [from_square, to_square].map { rank_number(_1) }
    (to_rank - from_rank) * direction
  end

  def file_shift(from_square, to_square)
    return unless square?(from_square) && square?(to_square)

    from_file, to_file = [from_square, to_square].map { file_index(_1) }
    to_file - from_file
  end
end
