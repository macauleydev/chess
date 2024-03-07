# require_relative "board"
module Move
  KNIGHT_LEAPS = [1, -1].product([2, -2]) + [2, -2].product([1, -1])
  DIAGONAL_STEPS = [1, -1].product([1, -1])
  FILE_STEPS = [1, -1].product([0])
  RANK_STEPS = [0].product([1, -1])
  STRAIGHT_STEPS = FILE_STEPS + RANK_STEPS
  ALL_STEPS = DIAGONAL_STEPS + STRAIGHT_STEPS

  def make_move(from_square, to_square)
    if real_board?
      raise "Illegal move attempted (#{from_square} to #{to_square})" \
        unless legal_move?(from_square, to_square, player.color)
    end

    capture_square =
      if occupied?(to_square)
        to_square
      elsif (en_passant = en_passant_attack?(from_square, to_square))
        en_passant_capture_square(from_square, to_square)
      end

    record_move(from_square, to_square, en_passant:) if real_board?
    make_capture_on(capture_square) if capture_square
    relocate_piece(from_square, to_square)
    rotate_players if real_board?
  end

  def make_capture_on(capture_square)
    record_capture_on(capture_square) if real_board?
    clear_square(capture_square)
  end

  def relocate_piece(from_square, to_square)
    piece = @contents[from_square]
    raise "There is no piece on #{from_square} to relocate." \
      unless occupied?(from_square)
    raise "#{piece&.class} on #{from_square} says it's on #{piece.square})" \
      unless piece.square == from_square

    @contents.delete(from_square)
    @contents[to_square] = piece unless to_square.nil?
    piece.square = to_square
  end

  def clear_square(square) =
    relocate_piece(square, nil)

  def record_move(from_square, to_square, en_passant: nil)
    movement = [from_square, to_square]
    piece = @contents[from_square]

    capture = occupied?(to_square) || en_passant
    captured_piece =
      if occupied?(to_square)
        @contents[to_square]
      elsif en_passant
        @contents[en_passant_capture_square(from_square, to_square)]
      end

    threatens = threatens_opposing_king?(from_square, to_square)
    traps = traps_opposing_king?(from_square, to_square)
    checkmate = threatens && traps
    check = threatens && !traps
    draw = traps && !threatens

    @moves << {from_square:, to_square:, movement:, piece:,
               capture:, captured_piece:, en_passant:,
               check:, checkmate:, draw:}
  end

  def record_capture_on(capture_square)
    @captures << @contents[capture_square]
  end

  def conceivable_moves(color: player.color)
    # Conceivable = to_square is reachable (though the move might endanger king)
    from_squares = squares_of(color:)
    from_squares.reduce([]) do |collected_moves, from_square|
      to_squares = reachable_squares(from_square)
      collected_moves + [from_square].product(to_squares)
    end
  end

  def legal_moves(color: player.color)
    conceivable_moves(color).filter do |from_square, to_square|
      !endangers_own_king?(from_square, to_square)
    end
  end

  def endangers_own_king?(from_square, to_square)
    return false if @contents[to_square].is_a?(King)
    # Above line somehow protects kings from each other

    move_color = color_on(from_square)
    hypothetical_board = clone
    hypothetical_board.make_move(from_square, to_square)
    hypothetical_board.king_threatened?(move_color)
  end

  def threatens_opposing_king?(from_square, to_square)
    return false unless real_board?

    move_color = color_on(from_square)
    hypothetical_board = clone
    hypothetical_board.make_move(from_square, to_square)
    hypothetical_board.king_threatened?(color_opposing(move_color))
  end

  def traps_opposing_king?(from_square, to_square)
    return false unless real_board?

    move_color = color_on(from_square)
    hypothetical_board = clone
    hypothetical_board.make_move(from_square, to_square)
    hypothetical_board.king_trapped?(color_opposing(move_color))
  end

  def legal_move?(from_square, to_square, color = color_on(from_square))
    return false unless color == color_on(from_square) # prevents player from moving opponent

    conceivable_move?(from_square, to_square) && !endangers_own_king?(from_square, to_square)
  end

  def conceivable_move?(from_square, to_square)
    # Conceivable = to_square is reachable (though the move might endanger king).

    # This predicate method and submethods calculate the conceivability of a move
    # using their own logic, which though duplicating the logic in
    # Board#reachable_squares (used by #conceivable_moves), is more
    # efficient than if it relied on generating all relevant squares/moves.

    conceivable_general_move?(from_square, to_square) &&
      conceivable_specific_move?(from_square, to_square)
  end

  def conceivable_general_move?(from_square, to_square)
    return false unless occupied?(from_square)
    return false unless square?(to_square)
    return false if compatriot_squares?(from_square, to_square)

    true
  end

  def conceivable_specific_move?(from_square, to_square)
    case @contents[from_square]
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
    pawn = @contents[pawn_square]
    side_steps = side_steps(pawn_square, to_square)
    forward_steps = forward_steps(pawn_square, to_square)

    if side_steps == 1 && forward_steps == 1
      occupied?(to_square) || en_passant_attack?(pawn_square, to_square)
    elsif side_steps == 0 && forward_steps == 1
      unoccupied?(to_square)
    elsif side_steps == 0 && forward_steps == 2
      pawn.unmoved? &&
        unoccupied?(to_square) &&
        path_clear?(pawn_square, to_square)
    else
      false
    end
  end

  def en_passant_attack?(attack_from_square, attack_to_square)
    return false unless
      forward_diagonal_step?(attack_from_square, attack_to_square)
    return false unless
      occupied?(attack_from_square) && unoccupied?(attack_to_square)

    defense_color = color_opposing(color_on(attack_from_square))

    defense_square_passed_over = attack_to_square
    defense_square_passed_from = square_ahead(defense_square_passed_over, -1, defense_color)
    defense_square_passed_to = square_ahead(defense_square_passed_over, 1, defense_color)

    defense_passing_movement = [defense_square_passed_from, defense_square_passed_to]
    defense_passing_pawn = @contents[defense_square_passed_to]

    last_movement == defense_passing_movement &&
      defense_passing_pawn.is_a?(Pawn) &&
      defense_passing_pawn.color == defense_color
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

  def straight?(square1, square2) =
    [forward_steps(square1, square2), side_steps(square1, square2)].one?(0)

  def diagonal?(square1, square2)
    # file_rank_change(from_square, to_square).map(&:abs) in [1..7 => _n, ^_n]
    return nil if square1 == square2

    file_distance(square1, square2) == rank_distance(square1, square2)
  end

  def adjacent?(square1, square2) =
    ALL_STEPS.include?(file_rank_change(square1, square2))

  def knight_leap?(square1, square2) =
    KNIGHT_LEAPS.include?(file_rank_change(square1, square2))

  def forward_diagonal_step?(from_square, to_square, color = color_on(from_square) || White)
    forward_steps(from_square, to_square, color) == 1 &&
      side_steps(from_square, to_square) == 1
  end

  def side_steps(square1, square2) =
    file_distance(square1, square2)

  def forward_steps(from_square, to_square, color = color_on(from_square) || White)
    rank_increase(from_square, to_square, color)
  end

  def file_rank_change(from_square, to_square, color = color_on(from_square) || White)
    [file_shift(from_square, to_square),
      rank_increase(from_square, to_square, color)]
  end

  private

  def file_shift(from_square, to_square)
    return unless square?(from_square) && square?(to_square)

    from_file, to_file = [from_square, to_square].map { file_index(_1) }
    to_file - from_file
  end

  def file_distance(square1, square2) =
    file_shift(square1, square2).abs

  def rank_increase(from_square, to_square, color = color_on(from_square) || White)
    return unless square?(from_square) && square?(to_square)

    from_rank, to_rank = [from_square, to_square].map { |sq| rank_number(sq) }
    (to_rank - from_rank) * color.direction
  end

  def rank_distance(square1, square2) =
    rank_increase(square1, square2).abs
end
