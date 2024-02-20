require 'paint'
require_relative 'move'
require_relative 'piece'
require_relative 'player'

class Board # rubocop:disable Style/Documentation,Metrics/ClassLength
  FILE_LETTERS = ('a'..'h')
  RANK_NUMBERS = (1..8)
  RANK_NAMES = ('1'..'8')

  COLORS = [White, Black].freeze
  PIECE_TYPES = Piece.subclasses
  INITIAL_FILES = {
    Rook => %w[a h], Knight => %w[b g], Bishop => %w[c f],
    Queen => %w[d], King => %w[e],
    Pawn => %w[a b c d e f g h]
  }.freeze
  INITIAL_RANK_OFFSET = { Rook => 0, Knight => 0, Bishop => 0, Queen => 0, King => 0, Pawn => 1 }.freeze

  include Move
  def initialize(players: [Player.new(White), Player.new(Black)], # rubocop:disable Metrics/MethodLength
                 contents: nil, moves: nil, captures: nil, hypothetical: false)
    @players = players
    @contents = if contents.nil?
                  initial_contents(players)
                else
                  contents.clone.transform_values(&:clone)
                end
    @moves = moves.nil? ? [] : moves.clone
    @captures = captures.nil? ? [] : captures.clone
    @hypothetical = hypothetical

    @label_rank_left = true
    @label_rank_right = false
    @label_file_above = false
    @label_file_below = true
  end
  attr_accessor :contents, :moves
  attr_reader :players, :captures

  def clone
    # puts "self: #{inspect}"
    self.class.new(players:, contents:, moves:, captures:, hypothetical: true)
  end

  def hypothetical?
    @hypothetical
  end

  def player
    players[0]
  end

  def rotate_players
    players.rotate!
  end

  def king_trapped?(color)
    raise "Invalid color #{color} (must be one of #{COLORS})" unless COLORS.include?(color)

    possible_moves(color:).all? do |from_square, to_square|
      would_endanger_own_king?(from_square, to_square)
    end
  end

  def inverse(color)
    raise "Invalid color #{color} (must be one of #{COLORS})" unless COLORS.include?(color)

    COLORS.find { _1 != color }
  end

  def kings_square(color)
    matching_squares = squares_of(color:, type: King)
    unless matching_squares.count == 1
      raise "Interregnum alert! Found #{matching_squares.count} #{color.name} kings on this #{hypothetical? ? 'hypothetical' : 'actual'} board.\nBoard contents:\n#{@contents}"
    end

    matching_squares.first
  end

  def king_threatened?(color)
    raise "Invalid color #{color} (must be one of #{COLORS})" unless COLORS.include?(color)

    kings_square = kings_square(color)
    opponents_squares = squares_of(color: inverse(color))
    opponents_squares.any? { |opponents_square| valid_move?(opponents_square, kings_square) }
  end

  def initial_contents(players) # rubocop:disable Metrics/MethodLength
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

  def squares_between(from_square, to_square) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    raise "Invalid squares(s): #{from_square} and/or #{to_square}" unless all_square?(from_square, to_square)

    from_x, from_y = file_rank_index(from_square)
    to_x, to_y = file_rank_index(to_square)
    delta_x = to_x - from_x
    delta_y = to_y - from_y
    return unless [delta_x.abs, delta_y.abs] in [2..7, 0] | [0, 2..7] | [2..7 => _steps, ^_steps]

    steps = [delta_x.abs, delta_y.abs].max
    x_step = delta_x / steps
    y_step = delta_y / steps
    (1...steps).map do |i|
      square_at(from_x + (i * x_step), from_y + (i * y_step))
    end
  end

  def squares_diagonal(from_square)
    squares(from_square, directions: DIAGONAL_STEPS, step_counts: (1..7))
  end

  def squares_straight(from_square)
    squares(from_square, directions: STRAIGHT_STEPS, step_counts: (1..7))
  end

  def squares_adjacent(from_square)
    squares(from_square,
            directions: STRAIGHT_STEPS + DIAGONAL_STEPS,
            step_counts: (1..1))
  end

  def squares_front(from_square, step_counts: (1..1))
    squares(from_square, directions: RANK_STEPS, step_counts:)
      .filter { |to_square| rank_would_grow(from_square, to_square).positive? }
  end

  def squares_front_diagonal(from_square)
    squares(from_square, directions: DIAGONAL_STEPS, step_counts: (1..1))
      .filter { |to_square| rank_would_grow(from_square, to_square).positive? }
  end

  def squares_knight_leap(from_square)
    squares(from_square, directions: KNIGHT_LEAPS, step_counts: (1..1))
  end

  def squares(square, directions: nil, step_counts: (1..7)) # rubocop:disable Metrics/MethodLength
    raise "Invalid square, #{square}" unless square?(square)
    raise 'Must specify an array of directions' unless directions in Array

    x, y = file_rank_index(square)
    squares = []
    directions.each do |x_delta, y_delta|
      step_counts.each do |step_count|
        new_xy = [x + (x_delta * step_count), y + (y_delta * step_count)]
        squares << square_at(*new_xy) if new_xy in [0..7, 0..7]
      end
    end
    squares
  end

  def squares_reachable_from(from_square) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    piece = @contents[from_square]
    case piece
    when Pawn
      max_steps = piece.unmoved? ? 2 : 1
      step_moves = squares_front(from_square, step_counts: (1..max_steps)).filter do |to_square|
        square_empty?(to_square) && empty_between?(from_square, to_square) && valid_move?(from_square, to_square)
      end
      attack_moves = squares_front_diagonal(from_square).filter do |to_square|
        if !valid_move?(from_square, to_square)
          false
        elsif occupied?(to_square)
          color_on(to_square) != piece.color
        else
          en_passant?(from_square, to_square)
        end
      end
      step_moves + attack_moves
    when Bishop
      squares_diagonal(from_square).filter do |to_square|
        color_on(to_square) != piece.color &&
          empty_between?(from_square, to_square) && valid_move?(from_square, to_square)
      end
    when Rook
      squares_straight(from_square).filter do |to_square|
        color_on(to_square) != piece.color &&
          empty_between?(from_square, to_square) && valid_move?(from_square, to_square)
      end
    when Queen
      to_squares = squares_diagonal(from_square) + squares_straight(from_square)
      to_squares.filter do |to_square|
        color_on(to_square) != piece.color &&
          empty_between?(from_square, to_square) && valid_move?(from_square, to_square)
      end
    when King
      squares_adjacent(from_square).filter do |to_square|
        color_on(to_square) != piece.color && valid_move?(from_square, to_square)
      end
    when Knight
      squares_knight_leap(from_square).filter do |to_square|
        color_on(to_square) != piece.color && valid_move?(from_square, to_square)
      end
    end
  end

  def pieces_reachable_from(from_square)
    squares_reachable_from(from_square).map { |square| @contents[square] }
  end

  def square_empty?(square)
    @contents[square].nil? && square?(square)
  end

  def squares_empty?(*squares)
    squares.all? { |square| square_empty?(square) }
  end

  def empty_between?(from_square, to_square)
    squares_empty?(*squares_between(from_square, to_square))
  end

  def occupied?(square)
    !@contents[square].nil?
  end

  def piece_type_on(square)
    @contents[square]&.class
  end

  def contents_of(color: nil, type: nil) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/MethodLength
    unless [nil,
            *COLORS].include?(color)
      raise "Invalid color #{color}\n
      doesn't match one of these:\n
      #{[nil, *COLORS]}"
    end

    selected_contents = if color
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
    RANK_NAMES.find_index(rank_name(square)) + (increase * color.direction)
  end

  def file_rank_index(square)
    [file_index(square), rank_index(square)]
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
    board_row = FILE_LETTERS.map do |file_letter|
      square = "#{file_letter}#{rank_name}"
      active = active_squares&.include?(square)
      square_to_s("#{file_letter}#{rank_name}", active:)
    end.join
    left = @label_rank_left ? "#{label_format(rank_name)} " : ''
    right = @label_rank_right ? " #{label_format(rank_name)}" : ''
    "#{left}#{board_row}#{right}\n"
  end

  def square_to_s(square, active: nil) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    raise "Invalid square, #{square}" unless square?(square)

    dark = (file_index(square) + rank_index(square)).even?

    bg = case [dark, active]
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
