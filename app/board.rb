require "paint"
require_relative "move"
require_relative "piece"
require_relative "player"

class Board
  FILE_LETTERS = ("a".."h")
  RANK_NUMBERS = (1..8)
  RANK_NAMES = ("1".."8")

  COLORS = [White, Black].freeze
  PIECE_TYPES = Piece.subclasses
  INITIAL_FILES = {
    Rook => %w[a h], Knight => %w[b g], Bishop => %w[c f],
    Queen => %w[d], King => %w[e],
    Pawn => %w[a b c d e f g h]
  }.freeze
  INITIAL_RANK_OFFSET = {Rook => 0, Knight => 0, Bishop => 0, Queen => 0, King => 0, Pawn => 1}.freeze

  include Move
  def initialize(players: [Player.new(White), Player.new(Black)],
    contents: nil, moves: nil, captures: nil, hypothetical: false)
    @players = players
    @contents =
      if contents.nil?
        initial_contents(players)
      else
        contents.clone.transform_values(&:clone)
      end
    @moves = moves.nil? ? [] : moves.clone
    @captures = captures.nil? ? [] : captures.clone
    @hypothetical = hypothetical
    @label_files = {above: false, below: true}
    @label_ranks = {left: true, right: false}
    @labels_hidden = false
  end
  attr_accessor :contents, :moves, :labels_hidden
  attr_reader :players, :captures

  def clone
    self.class.new(players:, contents:, moves:, captures:, hypothetical: true)
  end

  def hypothetical?
    @hypothetical
  end

  def player
    players[0]
  end

  def last_movement
    @moves&.last&.[](:movement)
  end

  def rotate_players
    players.rotate!
  end

  def king_trapped?(color)
    raise "Invalid color #{color} (must be one of #{COLORS})" unless COLORS.include?(color)

    conceivable_moves(color:).all? do |from_square, to_square|
      would_endanger_own_king?(from_square, to_square)
    end
  end

  def color_opposing(color)
    raise "Invalid color #{color} (must be one of #{COLORS})" unless COLORS.include?(color)

    COLORS.find { _1 != color }
  end

  def kings_square(color)
    matching_squares = squares_of(color:, type: King)
    unless matching_squares.count == 1
      raise "Interregnum alert! Found #{matching_squares.count} #{color.name} kings on this #{hypothetical? ? "hypothetical" : "actual"} board.\nBoard contents:\n#{@contents}"
    end

    matching_squares.first
  end

  def king_threatened?(color)
    raise "Invalid color #{color} (must be one of #{COLORS})" unless COLORS.include?(color)

    kings_square = kings_square(color)
    opponents_squares = squares_of(color: color_opposing(color))
    opponents_squares.any? { |opponents_square| legal_move?(opponents_square, kings_square) }
  end

  def initial_contents(players)
    contents = {}
    players.each do |player|
      color = player.color
      PIECE_TYPES.each do |piece_type|
        rank = color.lowest_rank + (color.direction * INITIAL_RANK_OFFSET[piece_type])
        INITIAL_FILES[piece_type].each do |file|
          square = "#{file}#{rank}"
          contents[square] = piece_type.new(color, [square])
        end
      end
    end
    contents
  end

  def color_on(square)
    @contents[square]&.color
  end

  def opposing_colors?(color1, color2)
    color1 == color_opposing(color2)
  end

  def compatriot_squares?(square1, square2)
    COLORS.include?(color_on(square1)) &&
      color_on(square1) == color_on(square2)
  end

  def opposing_squares?(square1, square2)
    opposing?(color_on(square1), color_on(square2))
  end

  def of_same_color?(p1, p2)
    p1.color == p2.color
  end

  def of_opposing_colors?(p1, p2)
    opposing_colors?(p1.color, p2.color)
  end

  def square_at(file_index, rank_index)
    file_letter = FILE_LETTERS.to_a[file_index]
    rank_number = RANK_NUMBERS.to_a[rank_index]
    "#{file_letter}#{rank_number}"
  end

  def square?(square)
    square.chars in [FILE_LETTERS, RANK_NAMES]
  end

  def all_square?(*squares)
    squares.all? { |square| square?(square) }
  end

  def squares_between(from_square, to_square)
    raise "Invalid squares(s): #{from_square} and/or #{to_square}" unless all_square?(from_square, to_square)
    return [] unless straight?(from_square, to_square) || diagonal?(from_square, to_square)

    x_start, y_start = file_rank_index(from_square)
    x_end, y_end = file_rank_index(to_square)

    total_x_delta = x_end - x_start
    total_y_delta = y_end - y_start
    total_steps = [total_x_delta.abs, total_y_delta.abs].max
    x_step = total_x_delta / total_steps
    y_step = total_y_delta / total_steps

    (1...total_steps).map do |number_of_steps|
      x_delta = x_step * number_of_steps
      y_delta = y_step * number_of_steps
      square_at(x_start + x_delta, y_start + y_delta)
    end
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

  def square_forward(from_square, forward_steps = 1, color = color_on(from_square))
    file_index = file_index(from_square)
    direction = color.direction
    rank_index = rank_index(from_square) + (forward_steps * direction)
    return nil unless rank_index in 0..7
    square_at(file_index, rank_index)
  end

  def squares_forward_diagonal(from_square, forward_steps = 1)
    left_file = file_index(from_square) - 1
    right_file = file_index(from_square) + 1
    forward_rank = rank_index(from_square) + forward_steps

    index_pairs =
      [[left_file, forward_rank],
        [right_file, forward_rank]].filter { |indexes| indexes in [0..7, 0..7] }

    squares = index_pairs.map { |file_index, rank_index| square_at(file_index, rank_index) }
    puts "Squares forward diagonal from #{from_square}: #{squares}"
    squares
  end

  def en_passant_capture_square(attack_from_square, attack_to_square)
    attack_color = color_on(attack_from_square)
    square_forward(attack_to_square, -1, attack_color)
  end

  def squares_knight_leap(from_square)
    squares(from_square, step_types: KNIGHT_LEAPS, numbers_of_steps: (1..1))
  end

  def squares(square, step_types: nil, numbers_of_steps: (1..7))
    raise "Invalid square, #{square}" unless square?(square)
    raise "Must specify an array of step types" unless step_types in Array

    x, y = file_rank_index(square)
    squares = []
    step_types.each do |x_step, y_step|
      numbers_of_steps.each do |number_of_steps|
        x_delta = x_step * number_of_steps
        y_delta = y_step * number_of_steps
        new_x, new_y = [x + x_delta, y + y_delta]
        squares << square_at(new_x, new_y) if [new_x, new_y] in [0..7, 0..7]
      end
    end
    squares
  end

  def reachable_squares(from_square)
    # Reachable: conceivable (even if it would endanger king)
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
    else
      "unrecognized piece type"
    end
  end

  def pawn_reachable_squares(pawn_square)
    pawn = @contents[pawn_square]
    square_one_forward = square_forward(pawn_square)
    square_two_forward = square_forward(pawn_square, 2)

    step_squares = []
    step_squares << square_one_forward if unoccupied?(square_one_forward)
    step_squares << square_two_forward if pawn.unmoved?

    diagonal_squares =
      squares_forward_diagonal(pawn_square, 1).filter do |to_square|
        opponent_on?(to_square) || en_passant_attack?(pawn_square, to_square)
      end

    step_squares + diagonal_squares
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

  def pieces_reachable_from(from_square)
    reachable_squares(from_square).map { |square| @contents[square] }
  end

  def occupied?(square)
    raise "#{square} is not a square" unless square?(square)
    !@contents[square].nil?
  end

  def unoccupied?(square)
    raise "#{square} is not a square" unless square?(square)
    @contents[square].nil?
  end

  def path_clear?(from_square, to_square)
    squares_between(from_square, to_square).all? { |square| unoccupied?(square) }
  end

  def path_blocked?(from_square, to_square)
    squares_between(from_square, to_square).any? { |square| occupied?(square) }
  end

  def opponent_on?(square)
    color_on(square) == (player.color)
  end

  def compatriot_on?(square)
    color_on(square) == player.color
  end

  def piece_type_on(square)
    @contents[square]&.class
  end

  def opposing_pawn_on?(square)
    puts "Opponent on #{square}? #{opponent_on?(square)}"
    opponent_on?(square) && piece_type_on(square) == Pawn
  end

  def contents_of(color: nil, type: nil)
    unless [nil,
      *COLORS].include?(color)
      raise "Invalid color #{color}\n
      doesn't match one of these:\n
      #{[nil, *COLORS]}"
    end

    selected_contents =
      if color
        @contents.select { |_square, piece| piece&.color == color }
      else
        @contents.select { |square, _piece| occupied?(square) }
      end
    selected_contents.select! { |_square, piece| piece.instance_of?(type) } if type
    selected_contents
  end

  def squares_of(color: nil, type: nil)
    contents_of(color:, type:).map { |square, _piece| square }
  end

  def pieces_of(color: nil, type: nil)
    contents_of(color:, type:).map { |_square, piece| piece }
  end

  def white_occupied_squares
    squares_of(color: White)
  end

  def black_occupied_squares
    squares_of(color: Black)
  end

  def white_pieces
    pieces_of(color: White)
  end

  def black_pieces
    pieces_of(color: Black)
  end

  def captured_pieces(color: nil, type: nil)
    pieces = @captures.clone
    pieces.select! { |piece| piece.color == color } if color
    pieces.select! { |piece| piece.instance_of?(type) } if type
    pieces
  end

  def file_letter(square)
    square[0] if square?(square)
  end

  def rank_name(square)
    square[1] if square?(square)
  end

  def rank_number(square)
    rank_name(square).to_i
  end

  def file_index(square)
    FILE_LETTERS.find_index(file_letter(square))
  end

  def rank_index(square, increase: 0, color: color_on(square) || White)
    direction = color ? color.direction : 1
    RANK_NAMES.find_index(rank_name(square)) + (increase * direction)
  end

  def file_rank_index(square)
    [file_index(square), rank_index(square)]
  end

  def to_s(active_squares: nil)
    board_rows = RANK_NAMES.reverse_each.reduce("") do |partial_board, rank_name|
      partial_board + rank_to_s(rank_name, active_squares:)
    end
    above = @label_files[:above] ? file_labels_row : ""
    below = @label_files[:below] ? file_labels_row : ""
    above + board_rows + below
  end

  def rank_to_s(rank_name, active_squares: nil)
    board_row = FILE_LETTERS.map do |file_letter|
      square = "#{file_letter}#{rank_name}"
      active = active_squares&.include?(square)
      square_to_s("#{file_letter}#{rank_name}", active:)
    end.join
    left = @label_ranks[:left] ? "#{label_format(rank_name)} " : ""
    right = @label_ranks[:right] ? " #{label_format(rank_name)}" : ""
    "#{left}#{board_row}#{right}\n"
  end

  def square_to_s(square, active: nil)
    raise "Invalid square, #{square}" unless square?(square)

    dark = (file_index(square) + rank_index(square)).even?

    bg =
      case [dark, active]
      in [true, nil|false] then bg_dark
      in [true, true] then bg_dark_active
      in [false, nil|false] then bg_light
      in [false, true] then bg_light_active
      else puts "Failed pattern matching. dark = #{dark}, active = #{active}."
      end
    # bg = bg_dark_active if square == 'd2'
    # bg = bg_light_active if square == 'd7'
    piece = @contents[square]
    fg, symbol = if occupied?(square)
      [piece.color.color_code, piece.symbol]
    else
      [nil, " "]
    end
    symbol = piece.symbol_alt if @moves&.last&.[](:check) && square == kings_square(player.color)

    Paint["#{symbol} ", fg, bg]
  end

  def file_labels_row
    left = @label_ranks[:left] ? "  " : ""
    right = @label_ranks[:right] ? "  " : ""
    labels = "#{label_format(FILE_LETTERS.to_a.join(" "))} "
    "#{left}#{labels}#{right}\n"
  end

  def label_format(string)
    if @labels_hidden
      string = string.replace(" " * string.length)
    end
    Paint[string, fg_faded]
  end

  def bg_dark
    "#cc7c2b"
  end

  def bg_light
    "#e8a869"
  end

  def bg_dark_active
    "#a09512"
  end

  def bg_light_active
    "#c3bb62"
  end

  def fg_faded
    "#777777"
  end
end
