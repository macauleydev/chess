# require_relative "board"
module Move
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

  private

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

  def make_capture_on(capture_square)
    record_capture_on(capture_square) if real_board?
    clear_square(capture_square)
  end

  def record_capture_on(capture_square)
    @captures << @contents[capture_square]
  end

  def clear_square(square) =
    relocate_piece(square, nil)

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
end
