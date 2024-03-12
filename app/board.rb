Color = Data.define(:name, :color_code, :lowest_rank, :direction)
White = Color.new("White", "#ffffff", 1, 1)
Black = Color.new("Black", "#000000", 8, -1)

# Classes:
require_relative "player"
require_relative "piece"

# Modules:
require_relative "grid"
require_relative "display"
require_relative "explore"
require_relative "plan"
require_relative "judge"
require_relative "move"

class Board
  include Grid
  include Display
  include Explore
  include Plan
  include Judge
  include Move

  def initialize(players: new_players, contents: {}, moves: [], captures: [], real: true)
    @players = players
    @contents = contents.empty? ? initial_contents :
        contents.clone.transform_values(&:clone)
    @moves = moves.empty? ? moves : moves.clone
    @captures = captures.empty? ? captures : captures.clone
    @real = real
    @label_files = {top: false, bottom: true}
    @label_ranks = {left: true, right: false}
  end
  attr_reader :players, :contents, :moves, :captures

  def new_players = [Player.new(White), Player.new(Black)]

  def player = players[0]

  private def rotate_players = players.rotate!

  INITIAL_FILES = {
    Pawn => %w[a b c d e f g h],
    Rook => %w[a h], Knight => %w[b g], Bishop => %w[c f],
    Queen => %w[d], King => %w[e]
  }.freeze
  INITIAL_RANK_OFFSET = {
    Pawn => 1,
    Rook => 0, Knight => 0, Bishop => 0, Queen => 0, King => 0
  }.freeze

  def initial_contents
    contents = {}
    [White, Black].each do |color|
      Piece.subclasses.each do |piece_type|
        rank = color.lowest_rank + (color.direction * INITIAL_RANK_OFFSET[piece_type])
        INITIAL_FILES[piece_type].each do |file|
          square = "#{file}#{rank}"
          contents[square] = piece_type.new(color, self, [square])
        end
      end
    end
    contents
  end

  def check? = @moves&.last&.[](:check)

  def checkmate? = @moves&.last&.[](:checkmate)

  def draw? = @moves&.last&.[](:draw)

  private

  def last_movement = @moves&.last&.[](:movement)

  def square(from_square, file_shift, rank_increase, color = color_on(from_square) || White)
    file_index = file_index(from_square) + file_shift
    rank_index = rank_index(from_square) + (rank_increase * color.direction)
    square_at(file_index, rank_index)
  end

  def occupied?(square) = !@contents[square].nil?

  def unoccupied?(square) = @contents[square].nil?

  def color_on(square) = @contents[square]&.color

  def compatriot_squares?(square1, square2)
    color_on(square1) &&
      color_on(square1) == color_on(square2)
  end

  def opposing_squares?(square1, square2)
    color1, color2 = [color_on(square1), color_on(square2)]
    [color1, color2] in [White, Black] | [Black, White]
  end

  def color_opposing(color)
    return unless [White, Black].include?(color)
    [White, Black].find { _1 != color }
  end

  ################# Methods for potential future use: ####################

  def square_behind(from_square, rank_decrease = 1, color = color_on(from_square) || White)
    square(from_square, 0, -1 * rank_decrease, color)
  end

  def square_kingside(from_square, file_shift = 1)
    square(from_square, file_shift, 0)
  end

  def square_queenside(from_square, file_shift = -1)
    square(from_square, file_shift, 0)
  end

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
