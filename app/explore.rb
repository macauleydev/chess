module Explore
  def squares_of(color: nil, type: nil)
    contents_of(color:, type:).map { |square, _piece| square }
  end

  private def contents_of(color: nil, type: nil)
    @contents.select do |_square, piece|
      color_select = color.nil? || color == piece&.color
      type_select = type.nil? || type == piece&.class
      piece && color_select && type_select
    end
  end

  def kings_square(color)
    king_squares = squares_of(color:, type: King)
    king_squares.count == 1 or raise "Interregnum! This \
        #{real_board? ? "real" : "imaginary"} board has \
        #{matching_squares.count} #{color.name} kings!\n#{@contents}"
    king_squares.first
  end

  def en_passant_capture_square(attack_from_square, attack_to_square)
    if forward_diagonal_step?(attack_from_square, attack_to_square, White)
      color = White
    elsif forward_diagonal_step?(attack_from_square, attack_to_square, Black)
      color = Black
    else
      return
    end

    attack_from_rank = rank_number(attack_from_square)
    relative_rank_5 = color.lowest_rank + (4 * color.direction)
    return unless attack_from_rank == relative_rank_5

    attack_to_file = file_letter(attack_to_square)
    "#{attack_to_file}#{attack_from_rank}"
  end

  def squares_between(square1, square2)
    span = [square1, square2]
    return [] unless straight?(*span) || diagonal?(*span)

    total_steps = [file_distance(*span), rank_distance(*span)].max
    file_step = file_shift(*span) <=> 0
    rank_step = rank_increase(*span) <=> 0

    (1...total_steps).map do |step_count|
      square(square1, file_step * step_count, rank_step * step_count)
    end
  end

  private def path_clear?(square1, square2) =
    squares_between(square1, square2).all? { unoccupied?(_1) }

  def reachable_squares(from_square)
    # Reachable = the move is conceivable (though might endanger king)

    piece = @contents[from_square]
    return false unless square?(from_square)
    return false if piece.nil?

    case piece
    when Pawn then pawn_reachable_squares(from_square)
    when Bishop then bishop_reachable_squares(from_square)
    when Rook then rook_reachable_squares(from_square)
    when Queen then queen_reachable_squares(from_square)
    when King then king_reachable_squares(from_square)
    when Knight then knight_reachable_squares(from_square)
    else "unrecognized piece type"
    end
  end

  private

  def pawn_reachable_squares(pawn_square)
    pawn = @contents[pawn_square]
    square_ahead = square_ahead(pawn_square)
    square_ahead_2 = square_ahead(pawn_square, 2)

    squares_ahead = []
    squares_ahead << square_ahead if unoccupied?(square_ahead)
    squares_ahead << square_ahead_2 if pawn.unmoved? &&
      unoccupied?(square_ahead_2) && path_clear?(pawn_square, square_ahead_2)

    attack_squares =
      [square_kingside_ahead(pawn_square),
        square_queenside_ahead(pawn_square)].compact
    attack_squares.filter! do |to_square|
      opposing_squares?(pawn_square, to_square) || en_passant_attack?(pawn_square, to_square)
    end

    squares_ahead + attack_squares
  end

  def bishop_reachable_squares(bishop_square)
    squares_diagonal(bishop_square).filter do |to_square|
      path_clear?(bishop_square, to_square) &&
        !compatriot_squares?(bishop_square, to_square)
    end
  end

  def rook_reachable_squares(rook_square)
    squares_straight(rook_square).filter do |to_square|
      path_clear?(rook_square, to_square) &&
        !compatriot_squares?(rook_square, to_square)
    end
  end

  def queen_reachable_squares(queen_square)
    to_squares = squares_diagonal(queen_square) + squares_straight(queen_square)
    to_squares.filter do |to_square|
      path_clear?(queen_square, to_square) &&
        !compatriot_squares?(queen_square, to_square)
    end
  end

  def king_reachable_squares(king_square)
    squares_adjacent(king_square).filter do |to_square|
      !compatriot_squares?(king_square, to_square)
    end
  end

  def knight_reachable_squares(knight_square)
    squares_knight_leap(knight_square).filter do |to_square|
      !compatriot_squares?(knight_square, to_square)
    end
  end

  def square_ahead(of_square, rank_increase = 1, color = color_on(of_square) || White)
    square(of_square, 0, rank_increase, color)
  end

  def square_kingside_ahead(of_square, color = color_on(of_square) || White)
    square(of_square, 1, 1, color)
  end

  def square_queenside_ahead(of_square, color = color_on(of_square) || White)
    square(of_square, -1, 1, color)
  end

  # Step types:
  KNIGHT_LEAPS = [1, -1].product([2, -2]) + [2, -2].product([1, -1])
  DIAGONAL_STEPS = [1, -1].product([1, -1])
  FILE_STEPS = [1, -1].product([0])
  RANK_STEPS = [0].product([1, -1])
  STRAIGHT_STEPS = FILE_STEPS + RANK_STEPS
  ALL_STEPS = DIAGONAL_STEPS + STRAIGHT_STEPS

  def squares(from_square, step_types: nil, numbers_of_steps: (1..7))
    raise "Invalid square, #{square}" unless square?(from_square)
    raise "Must specify an array of step types" unless step_types in Array

    step_types.flat_map do |file_step, rank_step|
      numbers_of_steps.map do |step_count|
        square(from_square, file_step * step_count, rank_step * step_count)
      end
    end.compact
  end

  def squares_diagonal(from_square)
    squares(from_square, step_types: DIAGONAL_STEPS, numbers_of_steps: (1..7))
  end

  def squares_straight(from_square)
    squares(from_square, step_types: STRAIGHT_STEPS, numbers_of_steps: (1..7))
  end

  def squares_adjacent(from_square)
    squares(from_square,
      step_types: STRAIGHT_STEPS + DIAGONAL_STEPS,
      numbers_of_steps: (1..1))
  end

  def squares_knight_leap(from_square)
    squares(from_square, step_types: KNIGHT_LEAPS, numbers_of_steps: (1..1))
  end
end
