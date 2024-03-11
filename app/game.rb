require "paint"

# Classes:
require_relative "board"

# Modules:
require_relative "input"
require_relative "notation"

class Game
  include Input
  include Notation
  def initialize(board = Board.new)
    @board = board
    @show_help = true
  end

  def play(skip_intro: false)
    introduce_game unless skip_intro
    take_turns
    finish_game
  end

  def introduce_game
    show_board(labels_hidden: true)
    puts "  Terminal Chess!"
    puts faded "  powered by Ruby"
    gets
    puts faded "If the chess pieces are hard to see,"
    puts "#{faded "hold your keyboard's"} Cmd #{faded "or"} Ctrl #{faded "key"}"
    puts "#{faded "and type"} = #{faded "(+) or"} - #{faded "to zoom in or out."}"
    gets
    puts faded "Both sides must be played by humans. Ready?"
    gets
  end

  def take_turns
    until game_over?
      from, to = get_legal_move
      perform_move(from, to)
    end
  end

  def game_over? = @board.checkmate? || @board.draw?

  def finish_game
    show_board
    puts @board.checkmate? ? "Checkmate!" : "Draw."
    gets
    menu = {"Y" => :save_game_and_exit, "N" => :exit}
    command_prompt("Save completed game (Y/N)? ", menu)
  end

  def show_board(active_squares: [], duration: 0, labels_hidden: false)
    game_notation = self
    chessboard = @board.to_s(active_squares:, labels_hidden:)

    clear_terminal
    puts game_notation
    puts
    puts chessboard

    sleep(duration)
  end

  def get_legal_move
    loop do
      introduce_move_prompt
      print("#{@board.player.name}'s move: ")
      input = gets.chomp
      return command(input) || legal_move(input) || next
    end
  end

  def introduce_move_prompt
    show_board
    maybe_show_check
    maybe_show_help
  end

  def maybe_show_check
    puts "Check!" if @board.check?
  end

  def maybe_show_help
    if @show_help || @board.moves.count.zero?
      entry_hint = "\nEnter move as coordinates (b1c3) or\nin minimal algebraic notation (Nc3).\nOr, type a command (save, load, quit).\n"
      @show_help = false
    else
      entry_hint = "\nEnter move (or ? for help).\n"
    end
    puts faded(entry_hint)
  end

  def command(input)
    # commands = {
    #   "?" => :show_help_next_prompt,
    #   "save" => :save_game_and_exit,
    #   "load" => :load_game_and_play,
    #   "quit" => :exit
    # }
    # command_prompt("", commands)
    case input
    when "?" then show_help_next_prompt
    when "save" then save_game_and_exit
    when "load" then load_game_and_play
    when "quit" then exit
    end
  end

  def show_help_next_prompt
    @show_help = true
    nil
  end

  def legal_move(input)
    movement = movement(input)
    return unless movement
    return unless @board.legal_move?(*movement, @board.player.color)

    movement
  end

  def perform_move(from, to)
    duration = 0.1
    show_board(active_squares: [from], duration:)
    show_board(active_squares: [from, to] + @board.squares_between(from, to), duration:)

    @board.make_move(from, to)

    show_board(active_squares: [from, to], duration: duration)
    show_board(active_squares: [to], duration:)
  end

  def clear_terminal
    system("clear") || system("cls")
  end

  def faded(string) = Paint[string, @board.fg_faded]
end
