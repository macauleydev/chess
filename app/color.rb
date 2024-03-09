module Color
  Color = Data.define(:name, :color_code, :lowest_rank, :direction)
  White = Color.new("White", "#ffffff", 1, 1)
  Black = Color.new("Black", "#000000", 8, -1)
  COLORS = [White, Black].freeze

  def color_opposing(color)
    COLORS.include?(color) or return nil
    COLORS.count == 2 or raise("Since when does chess have #{COLORS.count} COLORS?\n")

    COLORS.find { |the_only_other_color| color != the_only_other_color }
  end

  def opposing_colors?(color1, color2)
    color_opposing(color1) == color2
  end

  def color_on(square) = @contents[square]&.color

  def compatriot_squares?(square1, square2)
    color_on(square1) &&
      color_on(square1) == color_on(square2)
  end

  def opposing_squares?(square1, square2)
    opposing_colors?(color_on(square1), color_on(square2))
  end
end
