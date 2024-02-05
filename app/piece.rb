require_relative 'color'

class Piece
  def initialize(color, places)
    @color = color
    @places = places
    @place = places.last
  end

  def unmoved?
    @places.length = 1
  end
end

class Pawn < Piece
  def initialize(color, places)
    super
    @name = 'pawn'
    @key = 'P'
    @symbol = '♟'
  end
  attr_reader :color, :places, :name, :key, :symbol
end

class Rook < Piece
  def initialize(color, places)
    super
    @name = 'rook'
    @key = 'R'
    @symbol = '♜'
  end
  attr_reader :color, :places, :name, :key, :symbol
end

class Bishop < Piece
  def initialize(color, places)
    super
    @name = 'bishop'
    @key = 'B'
    @symbol = '♝'
  end
  attr_reader :color, :places, :name, :key, :symbol
end

class Knight < Piece
  def initialize(color, places)
    super
    @name = 'knight'
    @key = 'N'
    @symbol = '♞'
  end
  attr_reader :color, :places, :name, :key, :symbol
end

class Queen < Piece
  def initialize(color, places)
    super
    @name = 'queen'
    @key = 'Q'
    @symbol = '♛'
  end
  attr_reader :color, :places, :name, :key, :symbol
end

class King < Piece
  def initialize(color, places)
    super
    @name = 'king'
    @key = 'K'
    @symbol = '♚'
  end
  attr_reader :color, :places, :name, :key, :symbol
end
