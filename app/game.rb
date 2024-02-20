require_relative 'board'
require_relative 'color'
require_relative 'move'
require_relative 'piece'
require_relative 'player'

class Game # rubocop:disable Style/Documentation
  def initialize(board = Board.new)
    @board = board
  end

  def play # rubocop:disable Metrics/MethodLength,Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    loop do # rubocop:disable Metrics/BlockLength
      prompt, from, to = ''
      loop do
        show_board
        puts 'Check!' if check?
        print("\n" + prompt = "#{@board.player.name} moves from: ") # rubocop:disable Style/StringConcatenation
        from = gets.chomp
        break if @board.color_on(from) == @board.player.color && @board.squares_reachable_from(from)&.count&.positive?

        show_board(active_squares: [from])
        sleep(0.1)
      end
      loop do
        active_squares = [from] + @board.squares_reachable_from(from)
        show_board(active_squares:)
        print "\n#{@board.player.name} moves from #{from} to: "
        to = gets.chomp

        next unless @board.square?(to) && @board.valid_move?(from, to)

        @board.make_move(from, to)
        show_board(active_squares: [from, to])
        sleep(0.2)
        break
      end
      if checkmate?
        show_board
        puts 'Checkmate!'
        break
      elsif draw?
        show_board
        puts 'Draw.'
        break
      end
      # break if check
    end
  end

  def check?
    @board.moves&.last&.[](:check)
  end

  def checkmate?
    @board.moves&.last&.[](:checkmate)
  end

  def draw?
    @board.moves&.last&.[](:draw)
  end

  def show_board(active_squares: [])
    system('clear') || system('cls')
    puts @board.to_s(active_squares:)
  end

  def to_s # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    @board.moves.each_with_index.reduce('') do |game, (move, index)|
      if index.even?
        newline = "\n" if index.positive?
        move_pair_number = "#{newline}#{(index / 2) + 1}."
      end
      piece = (move[piece_type] in Pawn) ? '' : move[piece_type.key]
      to_square = move[to_square]
      capture = move[captured_square] ? 'x' : ''
      check = move[check] ? '+' : ''
      checkmate = move[checkmate] ? '#' : ''
      move = "#{piece}#{capture}#{to_square}#{check || checkmate}"
      move += "\n" if index.odd?
      game + "#{move_pair_number || ''} #{move}"
    end
  end
end
