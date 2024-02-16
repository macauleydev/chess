require_relative 'board'
require_relative 'color'
require_relative 'move'
require_relative 'piece'
require_relative 'player'

class Game # rubocop:disable Style/Documentation
  def initialize(board = Board.new)
    @board = board
  end

  def play # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity
    loop do
      prompt, from, to = ''
      loop do
        show_board
        puts 'Check!' if @board.check?
        print(prompt = "#{@board.player.name} moves from: ")
        from = gets.chomp
        break if @board.color_on(from) == @board.player.color && @board.squares_reachable_from(from)&.count&.positive?

        show_board(active_squares: [from])
        sleep(0.1)
      end
      loop do
        active_squares = [from] + @board.squares_reachable_from(from)
        show_board(active_squares:)
        print "#{@board.player.name} moves from #{from} to: "
        to = gets.chomp

        next unless @board.square?(to) && @board.valid_move?(from, to)

        @board.make_move(from, to)
        show_board(active_squares: [from, to])
        sleep(0.2)
        break
      end
      # break if check
      @board.rotate_players
    end
  end

  def show_board(active_squares: [])
    system('clear') || system('cls')
    puts @board.to_s(active_squares:)
  end
end
