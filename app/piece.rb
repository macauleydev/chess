class Piece
  def initialize(color, board, squares_visited)
    @color = color
    @color_code = color&.color_code
    @board = board
    @squares_visited = squares_visited.clone
  end

  def unmoved?
    @squares_visited.length == 1
  end

  def square=(square)
    @squares_visited << square unless square == @square
  end

  def square = @squares_visited.last

  def clone
    self.class.new(color, board, squares_visited)
  end

  attr_reader :color, :color_code, :board, :squares_visited, :name, :key, :symbol
end

class Pawn < Piece
  def initialize(color, board, squares_visited)
    super
    @name = "pawn"
    @key = "P"
    @symbol = "\u265F"
  end
end

class Rook < Piece
  def initialize(color, board, squares_visited)
    super
    @name = "rook"
    @key = "R"
    @symbol = "\u265C"
  end
end

class Knight < Piece
  def initialize(color, board, squares_visited)
    super
    @name = "knight"
    @key = "N"
    @symbol = "\u265E"
  end
end

class Bishop < Piece
  def initialize(color, board, squares_visited)
    super
    @name = "bishop"
    @key = "B"
    @symbol = "\u265D"
  end
end

class Queen < Piece
  def initialize(color, board, squares_visited)
    super
    @name = "queen"
    @key = "Q"
    @symbol = "\u265B"
  end
end

class King < Piece
  def initialize(color, board, squares_visited)
    super
    @name = "king"
    @key = "K"
  end

  def symbol
    @board.check? ? "\u2654" : "\u265A"
  end
end
