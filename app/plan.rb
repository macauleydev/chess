module Plan
  def real_board? = @real

  def clone
    self.class.new(players:, contents:, moves:, captures:,
      real: false)
  end

  def endangers_own_king?(from_square, to_square)
    return false if @contents[to_square].is_a?(King)
    # Above line somehow protects kings from each other

    move_color = color_on(from_square)
    imaginary_board = clone
    imaginary_board.make_move(from_square, to_square)
    imaginary_board.king_threatened?(move_color)
  end

  def threatens_opposing_king?(from_square, to_square)
    return false unless real_board?

    move_color = color_on(from_square)
    imaginary_board = clone
    imaginary_board.make_move(from_square, to_square)
    imaginary_board.king_threatened?(color_opposing(move_color))
  end

  def traps_opposing_king?(from_square, to_square)
    return false unless real_board?

    move_color = color_on(from_square)
    imaginary_board = clone
    imaginary_board.make_move(from_square, to_square)
    imaginary_board.king_trapped?(color_opposing(move_color))
  end

  def king_threatened?(color, skeptical = false)
    kings_square = kings_square(color)
    opponents_squares = squares_of(color: color_opposing(color))
    result = opponents_squares.any? do |opponents_square|
      legal_move?(opponents_square, kings_square)
    end
    if skeptical
      example_square = opponents_squares.find do |opponents_square|
        legal_move?(opponents_square, kings_square)
      end
      example_piece_type = @contents[example_square].class
      puts "#{color.name} King on #{real_board? ? "real" : "imaginary"} board is threatened, e.g. by #{example_piece_type} on #{example_square}."
    end
    result
  end

  def king_trapped?(color)
    conceivable_moves(color:).all? do |from_square, to_square|
      endangers_own_king?(from_square, to_square)
    end
  end

  private

  def conceivable_moves(color: player.color)
    # Conceivable = to_square is reachable (though the move might endanger king)
    from_squares = squares_of(color:)
    from_squares.reduce([]) do |collected_moves, from_square|
      to_squares = reachable_squares(from_square)
      collected_moves + [from_square].product(to_squares)
    end
  end

  ###################### For potential future use ######################
  def legal_moves(color: player.color)
    conceivable_moves(color).filter do |from_square, to_square|
      !endangers_own_king?(from_square, to_square)
    end
  end
end
