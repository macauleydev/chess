module Display
  require "paint"

  def to_s(active_squares: nil, labels_hidden: false)
    labels_top = file_labels(labels_hidden:)[:top]
    board_rows = RANK_NUMBERS.reverse_each.reduce("") do |top_of_board, rank_number|
      top_of_board + rank_to_s(rank_number, active_squares:, labels_hidden:)
    end
    labels_bottom = file_labels(labels_hidden:)[:bottom]
    labels_top + board_rows + labels_bottom
  end

  def fg_faded = "#777777"

  private

  def square_background
    dark, light = ["#cc7c2b", "#e8a869"]
    dark_active, light_active = ["#a09512", "#c3bb62"]
    {dark:, light:, dark_active:, light_active:}
  end

  def square_to_s(square, active: nil)
    dark = (file_index(square) + rank_index(square)).even?
    bg =
      case [dark, active]
      in [true, nil|false] then square_background[:dark]
      in [true, true] then square_background[:dark_active]
      in [false, nil|false] then square_background[:light]
      in [false, true] then square_background[:light_active]
      end
    piece = @contents[square]
    Paint[piece || "  ", nil, bg]
  end

  def rank_to_s(rank_number, active_squares: nil, labels_hidden: false)
    board_row = FILE_LETTERS.map do |file_letter|
      square = "#{file_letter}#{rank_number}"
      active = active_squares&.include?(square)
      square_to_s(square, active:)
    end.join
    rank_labels = rank_labels(rank_number, labels_hidden:)
    "#{rank_labels[:left]}#{board_row}#{rank_labels[:right]}\n"
  end

  def painted_label(label, labels_hidden: false)
    label = label.to_s if label.is_a?(Integer)
    label = hidden(label) if labels_hidden
    Paint[label, fg_faded]
  end

  def hidden(string)
    plain_string = Paint.unpaint(string)
    plain_string.replace(" " * plain_string.length)
  end

  def file_labels(labels_hidden: false)
    labels = "#{painted_label(FILE_LETTERS.to_a.join(" "), labels_hidden:)} "
    left_space = hidden(rank_labels(1)[:left])
    right_space = hidden(rank_labels(1)[:right])
    labels_row = "#{left_space}#{labels}#{right_space}\n"
    top = @label_files[:top] ? labels_row : ""
    bottom = @label_files[:bottom] ? labels_row : ""
    {top:, bottom:}
  end

  def rank_labels(rank_number, labels_hidden: false)
    rank_label = painted_label(rank_number, labels_hidden:)
    left = @label_ranks[:left] ? "#{rank_label} " : ""
    right = @label_ranks[:right] ? " #{rank_label}" : ""
    {left:, right:}
  end
end
