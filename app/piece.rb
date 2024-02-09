require_relative 'color'

class Piece # rubocop:disable Style/Documentation
  def initialize(color, squares_visited)
    @color = color
    @squares_visited = squares_visited
    @square = squares_visited.last
  end

  def unmoved?
    @squares_visited.length = 1
  end

  attr_reader :color, :squares_visited, :square, :name, :key, :symbol, :initial_files, :initial_rank_offset
end

class Pawn < Piece # rubocop:disable Style/Documentation
  def initialize(color, squares_visited)
    super
    @name = 'pawn'
    @key = 'P'
    @symbol = '♟'
  end
end

class Rook < Piece # rubocop:disable Style/Documentation
  def initialize(color, squares_visited)
    super
    @name = 'rook'
    @key = 'R'
    @symbol = '♜'
  end
end

class Knight < Piece # rubocop:disable Style/Documentation
  def initialize(color, squares_visited)
    super
    @name = 'knight'
    @key = 'N'
    @symbol = '♞'
  end
end

class Bishop < Piece # rubocop:disable Style/Documentation
  def initialize(color, squares_visited)
    super
    @name = 'bishop'
    @key = 'B'
    @symbol = '♝'
  end
end

class King < Piece # rubocop:disable Style/Documentation
  def initialize(color, squares_visited)
    super
    @name = 'king'
    @key = 'K'
    @symbol = '♚'
  end
end

class Queen < Piece # rubocop:disable Style/Documentation
  def initialize(color, squares_visited)
    super
    @name = 'queen'
    @key = 'Q'
    @symbol = '♛'
  end
end
