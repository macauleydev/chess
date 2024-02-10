require_relative 'board'
require_relative 'color'
require_relative 'move'
require_relative 'piece'
require_relative 'player'

class Game # rubocop:disable Style/Documentation
  def initialize(board = Board.new)
    @board = board
  end

  def play # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    loop do
      puts @board

      loop do
        prompt, from, to = ''
        loop do
          print(prompt = "#{@board.player.name} moves...from: ")
          from = gets.chomp
          next unless @board.square(from)&.color == @board.player.color

          print 'to: '.rjust(prompt.length)
          to = gets.chomp
          break if @board.a_square?(to)

          puts 'Try again.'
        end
        if @board.valid_move?(from, to)
          @board.move_piece(from, to)
          break
        else
          puts 'Try again.'
        end
      end

      # break if check
      @board.rotate_players
    end
  end
end
