require 'paint'
require_relative 'piece'
require_relative 'player'

class Board
  def initialize(players = [Player.new(White), Player.new(Black)], places = initial_places)
    @players = players
    @places = places
  end

  def initial_places # rubocop:disable Metrics/MethodLength
    places = {}
    [White, Black].each do |color|
      first_row_index = color.first_row
      first_row_pieces = [Rook, Knight, Bishop, Queen, King, Bishop, Knight, Rook]
      first_row_pieces.each_with_index do |piece, column_index|
        place = [column_index, first_row_index]
        places[place] = piece.new(color, [place])
      end

      second_row_index = color.first_row + color.direction
      (0..7).each do |column_index|
        place = [column_index, second_row_index]
        places[place] = Pawn.new(color, [place])
      end
    end
    places
  end

  def to_s # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    column_labels = ('a'..'h').to_a.join(' ')
    row_of_column_labels = Paint["  #{column_labels}\n", color_label]
    board_rows = ''
    7.downto(0) do |row_index|
      row_label = Paint[(row_index + 1).to_s, color_label]
      squares = ''
      0.upto(7) do |column_index|
        place = [column_index, row_index]
        piece = @places[place]
        symbol = piece&.symbol || ' '
        fg = piece&.color&.color_code
        bg = (row_index + column_index).odd? ? bg_light : bg_dark
        squares << Paint["#{symbol} ", fg, bg]
      end
      board_rows << "#{row_label} #{squares} #{row_label}\n"
    end
    row_of_column_labels + board_rows + row_of_column_labels
  end

  def bg_dark
    '#9f6122'
  end

  def bg_light
    '#e8a869'
  end

  def color_label
    '#777777'
  end
end
