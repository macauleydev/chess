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
  def initialize(players = [Player.new(White), Player.new(Black)],
                 squares = initial_squares(players), moves = [])
    @players = players
    @squares = squares
    @moves = moves

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

  def square(square_name)
    @squares[square_name] if a_square?(square_name)
  end

  def a_square?(square_name)
    square_name.chars in [FILE_LETTERS, RANK_NAMES]
  end

  def squares?(*square_names)
    square_names.all? { |square_name| a_square?(square_name) }
  end

  def available?(square_name)
    square(square_name).nil?
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

  def rank_index(square_name)
    RANK_NAMES.find_index(rank_name(square_name))
  end

  def to_s
    board_rows = RANK_NAMES.reverse_each.reduce('') do |partial_board, rank_name|
      partial_board + rank_to_s(rank_name)
    end
    above = @label_file_above ? file_labels_row : ''
    below = @label_file_below ? file_labels_row : ''
    above + board_rows + below
  end

  def rank_to_s(rank_name)
    board_row = FILE_LETTERS.map { |file_name| square_to_s("#{file_name}#{rank_name}") }.join
    left = @label_rank_left ? "#{label_format(rank_name)} " : ''
    right = @label_rank_right ? " #{label_format(rank_name)}" : ''
    "#{left}#{board_row}#{right}\n"
  end

  def square_to_s(square_name)
    return 'Invalid input' unless a_square?(square_name)

    file_index = FILE_LETTERS.find_index(square_name[0])
    rank_index = RANK_NAMES.find_index(square_name[1])
    bg = (file_index + rank_index).even? ? bg_dark : bg_light
    piece = @squares[square_name]
    fg = piece&.color&.color_code
    symbol = piece&.symbol || ' '
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
    '#9f6122'
  end

  def bg_light
    '#e8a869'
  end

  def fg_label
    '#777777'
  end
end
