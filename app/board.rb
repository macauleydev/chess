require 'paint'
require_relative 'move'
require_relative 'piece'
require_relative 'player'

class Board # rubocop:disable Style/Documentation,Metrics/ClassLength
  FILE_LETTERS = ('a'..'h')
  RANK_NUMBERS = (1..8)
  RANK_NAMES = ('1'..'8')

  PIECE_TYPES = Piece.subclasses
  INITIAL_FILES = {
    Rook => %w[a h], Knight => %w[b g], Bishop => %w[c f],
    Queen => %w[d], King => %w[e],
    Pawn => %w[a b c d e f g h]
  }.freeze
  INITIAL_RANK_OFFSET = { Rook => 0, Knight => 0, Bishop => 0, Queen => 0, King => 0, Pawn => 1 }.freeze

  include Move
  def initialize(players = [Player.new(White), Player.new(Black)], # rubocop:disable Metrics/ParameterLists
                 squares = initial_squares(players), moves = [], captures = [])
    @players = players
    @squares = squares
    @moves = moves
    @captures = captures

    @label_rank_left = true
    @label_rank_right = false
    @label_file_above = false
    @label_file_below = true
  end
  attr_accessor :squares, :moves
  attr_reader :players

  def player
    players[0]
  end

  def rotate_players
    players.rotate!
  end

  def initial_squares(players) # rubocop:disable Metrics/MethodLength
    squares = {}
    players.each do |player|
      color = player.color
      PIECE_TYPES.each do |piece_type|
        rank = color.lowest_rank + (color.direction * INITIAL_RANK_OFFSET[piece_type])
        INITIAL_FILES[piece_type].each do |file|
          square_name = "#{file}#{rank}"
          squares[square_name] = piece_type.new(color, [square_name])
        end
      end
    end
    squares
  end

  def piece_at(square_name, file_shift: 0, rank_increase: 0)
    if file_shift.zero? && rank_increase.zero?
      adjusted_square_name = square_name
    else
      adjusted_file = FILE_LETTERS.to_a[file_index(square_name) + file_shift]
      adjusted_rank = rank_number(square_name) + rank_increase
      adjusted_square_name = "#{adjusted_file}#{adjusted_rank}"
    end
    @squares[adjusted_square_name] if square?(adjusted_square_name)
  end

  def color_at(square_name)
    piece_at(square_name)&.color
  end

  def square_name(file_index, rank_index)
    file_letter = FILE_LETTERS.to_a[file_index]
    rank_number = RANK_NUMBERS.to_a[rank_index]
    "#{file_letter}#{rank_number}"
  end

  def square?(square_name)
    square_name.chars in [FILE_LETTERS, RANK_NAMES]
  end

  def all_square?(*square_names)
    square_names.all? { |square_name| square?(square_name) }
  end

  def squares_between(from_square, to_square) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    return unless all_square?(from_square, to_square)

    from_x, from_y = file_rank_index(from_square)
    to_x, to_y = file_rank_index(to_square)
    delta_x = to_x - from_x
    delta_y = to_y - from_y
    return unless [delta_x.abs, delta_y.abs] in [2..7, 0] | [0, 2..7] | [2..7 => _steps, ^_steps]

    steps = [delta_x.abs, delta_y.abs].max
    x_step = delta_x / steps
    y_step = delta_y / steps
    (1...steps).map do |i|
      square_name(from_x + (i * x_step), from_y + (i * y_step))
    end
  end

  def squares_diagonal(from_square)
    squares_from(from_square, directions: DIAGONAL_STEPS, step_counts: (1..7))
    # return unless square?(square_name)

    # from_x, from_y = file_rank_index(square_name)
    # directions = [1, -1].product([1, -1])
    # squares = []
    # directions.each do |x_step, y_step|
    #   x = from_x
    #   y = from_y
    #   while [x + x_step, y + y_step] in [0..7, 0..7]
    #     x += x_step
    #     y += y_step
    #     squares << square_name(x, y)
    #   end
    # end
    # p squares
    # squares
  end

  def squares_straight(from_square)
    squares_from(from_square, directions: STRAIGHT_STEPS, step_counts: (1..7))
  end

  def squares_adjacent(from_square)
    squares_from(from_square,
                 directions: STRAIGHT_STEPS + DIAGONAL_STEPS,
                 step_counts: (1..1))
  end

  def squares_front(from_square, step_counts: (1..1))
    squares_from(from_square, directions: RANK_STEPS, step_counts:)
      .filter { |to_square| rank_would_grow(from_square, to_square).positive? }
  end

  def squares_front_diagonal(from_square)
    squares_from(from_square, directions: DIAGONAL_STEPS, step_counts: (1..1))
      .filter { |to_square| rank_would_grow(from_square, to_square).positive? }
  end

  def squares_knight_leap(from_square)
    squares_from(from_square, directions: KNIGHT_LEAPS, step_counts: (1..1))
  end

  def squares_from(square_name, directions: nil, step_counts: (1..7)) # rubocop:disable Metrics/MethodLength
    return unless square?(square_name)

    x, y = file_rank_index(square_name)
    squares = []
    directions.each do |x_delta, y_delta|
      step_counts.each do |step_count|
        new_xy = [x + (x_delta * step_count), y + (y_delta * step_count)]
        squares << square_name(*new_xy) if new_xy in [0..7, 0..7]
      end
    end
    p squares
    squares
  end

  def valid_moves(from_square) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    piece = piece_at(from_square)

    case piece
    when Pawn
      max_steps = piece.unmoved? ? 2 : 1
      step_moves = squares_front(from_square, step_counts: (1..max_steps)).filter do |to_square|
        empty_square?(to_square) && empty_between?(from_square, to_square)
      end
      attack_moves = squares_front_diagonal(from_square).filter do |to_square|
        if occupied?(to_square)
          color_at(to_square) != piece.color
        else
          en_passant?(from_square, to_square)
        end
      end
      moves = step_moves + attack_moves
    when Bishop
      moves = squares_diagonal(from_square).filter do |to_square|
        color_at(to_square) != piece.color && empty_between?(from_square, to_square)
      end
    when Rook
      moves = squares_straight(from_square).filter do |to_square|
        color_at(to_square) != piece.color && empty_between?(from_square, to_square)
      end
    when Queen
      squares = squares_diagonal(from_square) + squares_straight(from_square)
      moves = squares.filter do |to_square|
        color_at(to_square) != piece.color && empty_between?(from_square, to_square)
      end
    when King
      moves = squares_adjacent(from_square).filter do |to_square|
        color_at(to_square) != piece.color
      end
    when Knight
      moves = squares_knight_leap(from_square).filter do |to_square|
        color_at(to_square) != piece.color
      end
    else moves = []
    end

    moves
  end

  def empty_square?(square_name)
    piece_at(square_name).nil? && square?(square_name)
  end

  def all_empty?(*square_names)
    square_names.all? { |square_name| empty_square?(square_name) }
  end

  def empty_between?(from_square, to_square)
    all_empty?(*squares_between(from_square, to_square))
  end

  def occupied?(square_name)
    !piece_at(square_name).nil?
  end

  def piece_type_at(square_name)
    piece_at(square_name)&.class
  end

  def white_pieces
    @squares.select { |_square_name, piece| piece.color == White }
  end

  def black_pieces
    @squares.select { |_square_name, piece| piece.color == Black }
  end

  def file_letter(square_name)
    square_name[0] if square?(square_name)
  end

  def rank_name(square_name)
    square_name[1] if square?(square_name)
  end

  def rank_number(square_name)
    rank_name(square_name).to_i
  end

  def file_index(square_name)
    FILE_LETTERS.find_index(file_letter(square_name))
  end

  def rank_index(square_name, increase: 0, color: piece_at(square_name)&.color || White)
    RANK_NAMES.find_index(rank_name(square_name)) + (increase * color.direction)
  end

  def file_rank_index(square_name)
    [file_index(square_name), rank_index(square_name)]
  end

  def to_s(active_squares: nil)
    board_rows = RANK_NAMES.reverse_each.reduce('') do |partial_board, rank_name|
      partial_board + rank_to_s(rank_name, active_squares:)
    end
    above = @label_file_above ? file_labels_row : ''
    below = @label_file_below ? file_labels_row : ''
    above + board_rows + below
  end

  def rank_to_s(rank_name, active_squares: nil)
    board_row = FILE_LETTERS.map do |file_name|
      square_name = "#{file_name}#{rank_name}"
      active = active_squares&.include?(square_name)
      square_to_s("#{file_name}#{rank_name}", active:)
    end.join
    left = @label_rank_left ? "#{label_format(rank_name)} " : ''
    right = @label_rank_right ? " #{label_format(rank_name)}" : ''
    "#{left}#{board_row}#{right}\n"
  end

  def square_to_s(square_name, active: nil) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    return 'Invalid input' unless square?(square_name)

    dark = (file_index(square_name) + rank_index(square_name)).even?

    bg = case [dark, active]
         in [true, nil|false] then bg_dark
         in [true, true] then bg_dark_active
         in [false, nil|false] then bg_light
         in [false, true] then bg_light_active
         else puts "Failed pattern matching. dark = #{dark}, active = #{active}."
         end
    # bg = bg_dark_active if square_name == 'd2'
    # bg = bg_light_active if square_name == 'd7'
    piece = piece_at(square_name)
    fg, symbol = if occupied?(square_name)
                   [piece.color.color_code, piece.symbol]
                 else
                   [nil, ' ']
                 end
    Paint["#{symbol} ", fg, bg]
  end

  def file_labels_row
    left = @label_rank_left ? '  ' : ''
    right = @label_rank_right ? '  ' : ''
    labels = "#{label_format(FILE_LETTERS.to_a.join(' '))} "
    "#{left}#{labels}#{right}\n"
  end

  def label_format(string)
    Paint[string, fg_label]
  end

  def bg_dark
    '#cc7c2b'
  end

  def bg_light
    '#e8a869'
  end

  def bg_dark_active
    '#a09512'
  end

  def bg_light_active
    '#c3bb62'
  end

  def fg_label
    '#777777'
  end
end
