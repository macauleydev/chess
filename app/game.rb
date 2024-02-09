require_relative 'board'
require_relative 'color'
require_relative 'move'
require_relative 'piece'
require_relative 'player'

class Game # rubocop:disable Style/Documentation
  def initialize(board = Board.new)
    @board = board
  end

  def play # rubocop:disable Metrics/AbcSize
    loop do
      puts @board
      print(prompt = "#{@board.player.name} moves from: ")
      from = gets.chomp
      print 'to: '.rjust(prompt.length)
      to = gets.chomp
      puts "#{@board.player.name} attempting move from #{from} to #{to}..."
      @board.move_piece(from, to)
      @board.rotate_players
    end
  end
end
