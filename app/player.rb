class Player
  def initialize(color)
    @color = color
    @name = color.name
    @direction = color.direction
    @color_code = color.color_code
  end
  attr_reader :name, :color, :color_code
end
