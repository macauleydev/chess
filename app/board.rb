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
    @squares[adjusted_square_name] if a_square?(adjusted_square_name)
  end

  def color_at(square_name)
    piece_at(square_name)&.color
  end

  def square_name(file_index, rank_index)
    file_letter = FILE_LETTERS.to_a[file_index]
    rank_number = RANK_NUMBERS.to_a[rank_index]
    "#{file_letter}#{rank_number}"
  end

  def a_square?(square_name)
    square_name.chars in [FILE_LETTERS, RANK_NAMES]
  end

  def squares?(*square_names)
    square_names.all? { |square_name| a_square?(square_name) }
  end

  def empty_square?(square_name)
    piece_at(square_name).nil? && a_square?(square_name)
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
    square_name[0] if a_square?(square_name)
  end

  def rank_name(square_name)
    square_name[1] if a_square?(square_name)
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
    return 'Invalid input' unless a_square?(square_name)

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
