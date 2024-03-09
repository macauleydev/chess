module Square
  FILE_LETTERS = ("a".."h")
  RANK_NUMBERS = (1..8)
  RANK_NAMES = ("1".."8")

  def square?(square)
    !!(square.chars in [FILE_LETTERS, RANK_NAMES])
  end

  def file_letter(square) = square[0]

  def rank_number(square) = square[1].to_i

  def square(from_square, file_shift, rank_increase, color = color_on(from_square) || White)
    file_index = file_index(from_square) + file_shift
    rank_index = rank_index(from_square) + (rank_increase * color.direction)

    square_at(file_index, rank_index)
  end

  def square_at(file_index, rank_index)
    return unless [file_index, rank_index] in [0..7, 0..7]

    file_letter = FILE_LETTERS.to_a[file_index]
    rank_number = RANK_NUMBERS.to_a[rank_index]
    "#{file_letter}#{rank_number}"
  end

  def file_index(square) = FILE_LETTERS.find_index(file_letter(square))

  def rank_index(square, increase: 0, color: color_on(square))
    direction = color ? color.direction : 1
    RANK_NUMBERS.find_index(rank_number(square)) + (increase * direction)
  end
end
