require_relative "player"
require_relative "piece"
require_relative "color"
require_relative "display"
require_relative "square"
require_relative "explore"
require_relative "plan"
require_relative "judge"
require_relative "move"

class Board
  include Color
  include Display
  include Square
  include Explore
  include Plan
  include Judge
  include Move

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

  def initialize(players: [Player.new(White), Player.new(Black)],
    contents: {}, moves: [], captures: [], real: true)
    @players = players
    @contents = contents.empty? ? initial_contents(players) :
        contents.clone.transform_values(&:clone)
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
