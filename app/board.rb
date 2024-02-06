require 'paint'
require_relative 'piece'
require_relative 'player'

class Board
  def initialize(players = [Player.new(White), Player.new(Black)], places = initial_places)
    @players = players
    @places = places
    @column_labels = ('a'..'h').to_a
    @row_labels = ('1'..'8').to_a
    @label_left = true
    @label_right = false
    @label_above = false
    @label_below = true
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

  def to_s
    board_rows = 7.downto(0).reduce('') do |board, row_index|
      board + row(row_index)
    end
    above = @label_above ? label_row : ''
    below = @label_below ? label_row : ''
    above + board_rows + below
  end

  def row_label(index)
    labels = ('1'..'8').to_a
    labels[index]
  end

  def column_label(index)
    labels = ('a'..'h')
    labels[index]
  end

  def label_format(string)
    Paint[string, fg_label]
  end

  def label_row
    left = @label_left ? '  ' : ''
    right = @label_right ? '  ' : ''
    labels = "#{label_format(@column_labels.join(' '))} "
    "#{left}#{labels}#{right}\n"
  end

  def square(column_index, row_index)
    place = [column_index, row_index]
    piece = @places[place]
    symbol = piece&.symbol || ' '
    fg = piece&.color&.color_code
    bg = (column_index + row_index).odd? ? bg_light : bg_dark
    Paint["#{symbol} ", fg, bg]
  end

  def row(row_index)
    label = label_format(row_label(row_index))
    board_row = (0..7).map { |column_index| square(column_index, row_index) }.join('')
    left = @label_left ? "#{label} " : ''
    right = @label_right ? " #{label}" : ''
    left + board_row + right + "\n"
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
