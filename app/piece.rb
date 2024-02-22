require_relative "color"

class Piece
  def initialize(color, squares_visited)
    @color = color
    @squares_visited = squares_visited.clone
  end

  def unmoved?
    @squares_visited.length == 1
  end

  def square=(square)
    @squares_visited << square unless square == @square
  end

  def square
    @squares_visited.last
  end

  def clone
    self.class.new(color, squares_visited)
  end

  def self.input_key
    @@input_key || @@key
  end

  def self.output_key
    @@output_key || @@key
  end

  def self.key
    @@key || @@output_key || @@input_key
  end

  @@key = @@input_key = @@output_key = nil
  attr_reader :color, :squares_visited, :name, :key, :symbol, :symbol_alt
end

class Pawn < Piece
  def initialize(color, squares_visited)
    super
    @name = "pawn"
    @@input_key = @key = "P"
    @@output_key = ""
    @symbol = "\u265F"
  end
end

class Rook < Piece
  def initialize(color, squares_visited)
    super
    @name = "rook"
    @@key = @key = "R"
    @symbol = "\u265C"
  end
end

class Knight < Piece
  def initialize(color, squares_visited)
    super
    @name = "knight"
    @@key = @key = "N"
    @symbol = "\u265E"
  end
end

class Bishop < Piece
  def initialize(color, squares_visited)
    super
    @name = "bishop"
    @@key = @key = "B"
    @symbol = "\u265D"
  end
end

class King < Piece
  def initialize(color, squares_visited)
    super
    @name = "king"
    @@key = @key = "K"
    @symbol = "\u265A"
    @symbol_alt = "\u2654"
  end
end

class Queen < Piece
  def initialize(color, squares_visited)
    super
    @name = "queen"
    @@key = @key = "Q"
    @symbol = "\u265B"
  end
end
