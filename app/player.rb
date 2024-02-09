require_relative 'piece'
require_relative 'color'

class Player # rubocop:disable Style/Documentation
  def initialize(color)
    @color = color
    @name = color.name
    @direction = color.direction
    @color_code = color.color_code
    # @pieces = initial_pieces
  end
  attr_reader :name, :color
end
