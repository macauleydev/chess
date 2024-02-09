require_relative 'board'
module Move # rubocop:disable Style/Documentation
  def move_piece(from_square, to_square) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    if !a_square?(from_square)
      puts "#{from_square} is not a valid position."
    elsif !a_square?(to_square)
      puts "#{to_square} is not a valid position."
    elsif available?(from_square)
      puts "Starting square #{from_square} contains no piece."
    elsif !available?(to_square)
      puts "Target square (#{to_square}) is occupied."
    else
      squares[to_square] = squares[from_square]
      squares[from_square] = nil
    end
  end
end
