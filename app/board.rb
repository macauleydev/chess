class Board
  def to_s
    rows = Array.new(8, content_row)
    inside = rows.join(middle_border_row)
    top_border_row + inside + bottom_border_row
  end

  def content_row
    border = '│'
    space = '   '
    row(border, space, border, border)
  end

  def top_border_row(start: '┌', cross: '┬', ending: '┐')
    border_row(start:, cross:, ending:)
  end

  def middle_border_row
    border_row
  end

  def bottom_border_row(start: '└', cross: '┴', ending: '┘')
    border_row(start:, cross:, ending:)
  end

  def border_row(start: '├', line: '───', cross: '┼', ending: '┤')
    row(start, line, cross, ending)
  end

  def row(left_border, cell, inner_border, right_border)
    cells = Array.new(8, cell)
    inside = cells.join(inner_border)
    left_border + inside + right_border + "\n"
  end
end
