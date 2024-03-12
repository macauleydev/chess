require "./app/board"

RSpec.describe Board do
  describe "#initialize" do
    context "when no contents are given" do
      subject(:board_initial_contents) { described_class.new }

      let(:contents) { board_initial_contents.contents }
      let(:squares_in_rank) do
        squares = {}
        (1..8).each do |rank|
          squares[rank] =
            ("a".."h").to_a.product([rank.to_s]).map { |f, r| f + r }
        end
        squares
      end

      let(:rank_1_squares) do
        ("a".."h").to_a.product(%w[1]).map { |f, r| f + r }
      end
      it "sets rank 1 with correct order of pieces" do
        rank_1_pieces = contents.values_at(*squares_in_rank[1])
        expect(rank_1_pieces).to satisfy("correctly ordered") do |pieces|
          pieces in
            [Rook, Knight, Bishop, Queen, King, Bishop, Knight, Rook]
        end
      end

      it "sets rank 8 with correct order of pieces" do
        rank_8_pieces = contents.values_at(*squares_in_rank[8])
        expect(rank_8_pieces).to satisfy("correctly ordered") do |pieces|
          pieces in
            [Rook, Knight, Bishop, Queen, King, Bishop, Knight, Rook]
        end
      end

      it "fills ranks 2 and 7 with Pawns" do
        rank_2_7_squares = [2, 7].flat_map { |r| squares_in_rank[r] }
        rank_2_7_pieces = contents.values_at(*rank_2_7_squares)
        expect(rank_2_7_pieces).to all(be_a(Pawn))
      end

      it "fills ranks 1 and 2 with White pieces" do
        rank_1_2_squares = [1, 2].flat_map { |r| squares_in_rank[r] }
        rank_1_2_pieces = contents.values_at(*rank_1_2_squares)
        expect(rank_1_2_pieces).to all(have_attributes(color: White))
      end

      it "fills ranks 7 and 8 with Black pieces" do
        rank_7_8_squares = [7, 8].flat_map { |r| squares_in_rank[r] }
        rank_7_8_pieces = contents.values_at(*rank_7_8_squares)
        expect(rank_7_8_pieces).to all(have_attributes(color: Black))
      end

      it "sets no pieces on ranks 3, 4, 5, and 6" do
        rank_3456_squares = (3..6).flat_map { |r| squares_in_rank[r] }
        rank_3456_contents = contents.values_at(*rank_3456_squares)
        expect(rank_3456_contents).to all(be_nil)
      end
    end
    context "when random contents are given" do
      subject(:board_random_contents) { described_class.new(contents: given_contents) }
      let(:board_stub) { double(Board) }
      let(:given_contents) do
        contents = {}
        [White, Black].each do |color|
          Piece.subclasses.each do |piece_type|
            square = ("a".."h").to_a.sample + ("1".."8").to_a.sample until contents[square].nil?
            contents[square] = piece_type.new(color, board_stub, [square])
          end
        end
        contents
      end
      let(:actual_contents) { board_random_contents.contents }

      it "preserves squares" do
        actual_squares = actual_contents.keys
        given_squares = given_contents.keys
        expect(actual_squares).to eql(given_squares)
      end
      it "preserves piece types" do
        actual_contents_types = actual_contents.transform_values(&:class)
        given_contents_types = given_contents.transform_values(&:class)
        expect(actual_contents_types).to eql(given_contents_types)
      end
      it "preserves piece colors" do
        actual_contents_colors = actual_contents.transform_values(&:color)
        given_contents_colors = given_contents.transform_values(&:color)
        expect(actual_contents_colors).to eql(given_contents_colors)
      end
      it "preserves piece histories" do
        actual_contents_histories = actual_contents.transform_values(&:squares_visited)
        given_contents_histories = given_contents.transform_values(&:squares_visited)
        expect(actual_contents_histories).to eql(given_contents_histories)
      end
    end
  end
end
