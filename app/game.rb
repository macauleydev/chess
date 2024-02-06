require_relative 'board'
require_relative 'color'
require_relative 'move'
require_relative 'piece'
require_relative 'player'

class Game
  def initialize(board, moves)
    @board = board
    @moves = moves
  end

  def players
    @board.players
  end
end
