module Judge
  def legal_move?(from_square, to_square, color = color_on(from_square))
    return false unless color == color_on(from_square) # prevents player from moving opponent

    !endangers_own_king?(from_square, to_square) &&
      conceivable_move?(from_square, to_square)
  end

  private

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

  def adjacent?(square1, square2)
    file_rank_distance(square1, square2) in [(0..1), (0..1)] unless
      square1 == square2
  end

  def knight_leap?(square1, square2)
    file_rank_distance(square1, square2) in [1, 2] | [2, 1]
  end

  def forward_diagonal_step?(from_square, to_square, color = color_on(from_square) || White)
    forward_steps(from_square, to_square, color) == 1 &&
      side_steps(from_square, to_square) == 1
  end

  def side_steps(square1, square2) =
    file_distance(square1, square2)

  def forward_steps(from_square, to_square, color = color_on(from_square) || White)
    rank_increase(from_square, to_square, color)
  end

  def file_distance(square1, square2) =
    file_shift(square1, square2).abs

  def rank_distance(square1, square2) =
    rank_increase(square1, square2).abs

  def file_rank_distance(square1, square2)
    [file_distance(square1, square2),
      rank_distance(square1, square2)]
  end

  def file_rank_change(from_square, to_square, color = color_on(from_square) || White)
    [file_shift(from_square, to_square),
      rank_increase(from_square, to_square, color)]
  end

  def file_shift(from_square, to_square)
    return unless square?(from_square) && square?(to_square)

    from_file, to_file = [from_square, to_square].map { file_index(_1) }
    to_file - from_file
  end

  def rank_increase(from_square, to_square, color = color_on(from_square) || White)
    return unless square?(from_square) && square?(to_square)

    from_rank, to_rank = [from_square, to_square].map { |sq| rank_number(sq) }
    (to_rank - from_rank) * color.direction
  end
end
