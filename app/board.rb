require "paint"
require_relative "display"
require_relative "move"
require_relative "piece"
require_relative "player"

class Board
  include Display
  include Move

  def initialize(players: [Player.new(White), Player.new(Black)],
    contents: {}, moves: [], captures: [], real: true)
    @players = players
    @contents =
      if contents.empty?
        initial_contents(players)
      else
        contents.clone.transform_values(&:clone)
      end
    @moves = moves.empty? ? moves : moves.clone
    @captures = captures.empty? ? captures : captures.clone
    @real = real
    @label_files = {top: false, bottom: true}
    @label_ranks = {left: true, right: false}
  end
  attr_accessor :labels_hidden
  attr_reader :contents, :moves, :players, :captures

  def player = players[0]

  def rotate_players = players.rotate!

  def last_movement = @moves&.last&.[](:movement)

  def check? = @moves&.last&.[](:check)

  def clone
    self.class.new(players:, contents:, moves:, captures:,
      real: false)
  end

  def real_board? = @real

  PIECE_TYPES = Piece.subclasses
  INITIAL_FILES = {
    Pawn => %w[a b c d e f g h],
    Rook => %w[a h], Knight => %w[b g], Bishop => %w[c f],
    Queen => %w[d], King => %w[e]
  }.freeze
  INITIAL_RANK_OFFSET = {
    Pawn => 1,
    Rook => 0, Knight => 0, Bishop => 0, Queen => 0, King => 0
  }.freeze

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

  def file_letter(square) = square[0]

  def rank_number(square) = square[1].to_i

  FILE_LETTERS = ("a".."h")
  RANK_NUMBERS = (1..8)
  RANK_NAMES = ("1".."8")

  def file_index(square) = FILE_LETTERS.find_index(file_letter(square))

  def rank_index(square, increase: 0, color: color_on(square))
    direction = color ? color.direction : 1
    RANK_NUMBERS.find_index(rank_number(square)) + (increase * direction)
  end

  def file_rank_index(square) = [file_index(square), rank_index(square)]

  def square?(square)
    square.chars in [FILE_LETTERS, RANK_NAMES]
  end

  def square_at(file_index, rank_index)
    file_letter = FILE_LETTERS.to_a[file_index]
    rank_number = RANK_NUMBERS.to_a[rank_index]
    "#{file_letter}#{rank_number}"
  end

  def square_forward(from_square, forward_steps = 1, color = color_on(from_square) || White )
    file_index = file_index(from_square)
    rank_index = rank_index(from_square) + (forward_steps * color.direction)
    return nil unless rank_index in 0..7
    square_at(file_index, rank_index)
  end

  def en_passant_capture_square(attack_from_square, attack_to_square)
    if forward_diagonal_step?(attack_from_square, attack_to_square, White)
      color = White
    elsif forward_diagonal_step?(attack_from_square, attack_to_square, Black)
      color = Black
    else
      return nil
    end

    starting_rank = rank_number(attack_from_square)
    return nil unless
      starting_rank == color.lowest_rank + (4 * color.direction)

    ending_file = file_letter(attack_to_square)
    "#{ending_file}#{starting_rank}"
  end

  def squares_forward_diagonal(from_square, forward_steps = 1)
    left_file = file_index(from_square) - 1
    right_file = file_index(from_square) + 1
    forward_rank = rank_index(from_square) + forward_steps

    index_pairs =
      [[left_file, forward_rank],
        [right_file, forward_rank]].filter { |indexes| indexes in [0..7, 0..7] }

    index_pairs.map { |file_index, rank_index| square_at(file_index, rank_index) }
  end

  COLORS = [White, Black].freeze

  def color_opposing(color)
    COLORS.include?(color) or return nil
    COLORS.count == 2 or raise("Since when does chess have #{COLORS.count} COLORS?\n")

    COLORS.find { |the_only_other_color| color != the_only_other_color }
  end

  def opposing_colors?(color1, color2)
    color_opposing(color1) == color2
  end

  def color_on(square) = @contents[square]&.color

  def compatriot_squares?(square1, square2)
    color_on(square1) &&
      color_on(square1) == color_on(square2)
  end

  def opposing_squares?(square1, square2)
    opposing_colors?(color_on(square1), color_on(square2))
  end

  def occupied?(square) = !@contents[square].nil?

  def unoccupied?(square) = @contents[square].nil?

  def path_clear?(from_square, to_square)
    squares_between(from_square, to_square).all? { |square| unoccupied?(square) }
  end

  def squares_between(from_square, to_square)
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
    step_squares << square_two_forward if pawn.unmoved? &&
      unoccupied?(square_two_forward) && path_clear?(pawn_square, square_two_forward)

    diagonal_squares =
      squares_forward_diagonal(pawn_square, 1).filter do |to_square|
        opposing_squares?(pawn_square, to_square) || en_passant_attack?(pawn_square, to_square)
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

  def squares_of(color: nil, type: nil)
    contents_of(color:, type:).map { |square, _piece| square }
  end

  def contents_of(color: nil, type: nil)
    @contents.select do |_square, piece|
      color_select = color.nil? || color == piece&.color
      type_select = type.nil? || type == piece&.class
      piece && color_select && type_select
    end
  end

  def kings_square(color)
    king_squares = squares_of(color:, type: King)
    king_squares.count == 1 or raise "Interregnum! This \
      #{real_board? ? "real" : "hypothetical"} board has \
      #{matching_squares.count} #{color.name} kings!\n#{@contents}"
    king_squares.first
  end

  def king_threatened?(color)
    kings_square = kings_square(color)
    opponents_squares = squares_of(color: color_opposing(color))
    opponents_squares.any? do |opponents_square|
      legal_move?(opponents_square, kings_square)
    end
  end

  def king_trapped?(color)
    conceivable_moves(color:).all? do |from_square, to_square|
      endangers_own_king?(from_square, to_square)
    end
  end

  ################# Methods for potential future use: ####################

  def piece_type_on(square) = @contents[square]&.class

  def pieces_reachable_from(from_square)
    reachable_squares(from_square).map { |square| @contents[square] }
  end

  # This method and @captures could be used to display captured pieces:
  def captured_pieces(color: nil, type: nil)
    @captures.select do |piece|
      color_select = color.nil? || color == piece&.color
      type_select = type.nil? || type == piece&.class
      piece && color_select && type_select
    end
  end

  # These methods could be used to display statistics:
  def white_occupied_squares = squares_of(color: White)

  def black_occupied_squares = squares_of(color: Black)

  def pieces_of(color: nil, type: nil)
    contents_of(color:, type:).map { |_square, piece| piece }
  end

  def white_pieces = pieces_of(color: White)

  def black_pieces = pieces_of(color: Black)
end
