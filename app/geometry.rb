FILE_LETTERS = ("a".."h")
RANK_NUMBERS = (1..8)
RANK_NAMES = ("1".."8")

module Geometry
  def square?(square) = !!(square.chars in [FILE_LETTERS, RANK_NAMES])

  def file_letter(square) = square[0]

  def rank_number(square) = square[1].to_i

  def rank_name(square) = square[1]

  def file_index(square) = FILE_LETTERS.find_index(file_letter(square))

  def rank_index(square) = RANK_NUMBERS.find_index(rank_number(square))

  def square_at(file_index, rank_index)
    return unless [file_index, rank_index] in [0..7, 0..7]

    file_letter = FILE_LETTERS.to_a[file_index]
    rank_number = RANK_NUMBERS.to_a[rank_index]
    "#{file_letter}#{rank_number}"
  end
end
