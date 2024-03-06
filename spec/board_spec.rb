require "./app/board"

RSpec.describe Board do
  describe "#initialize" do
    context "when no contents are specified" do
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

      it "sets no pieces on ranks 3,4,5,6" do
        rank_3456_squares = (3..6).flat_map { |r| squares_in_rank[r] }
        rank_3456_contents = contents.values_at(*rank_3456_squares)
        expect(rank_3456_contents).to all(be_nil)
      end
    end
  end
  context "when querying square c5" do
    subject(:board_square_names) { described_class.new }
    let(:square) { "c5" }

    describe "#file_letter" do
      let(:file_letter) { board_square_names.file_letter(square) }
      it "is the String c" do
        expect(file_letter).to eql("c")
      end
    end

    describe "#rank_number" do
      let(:rank_number) { board_square_names.rank_number(square) }
      it "is the Integer 5" do
        expect(rank_number).to eql(5)
      end
    end

    describe "#file_index" do
      let(:file_index) { board_square_names.file_index(square) }
      it "is 2" do
        expect(file_index).to eql(2)
      end
    end

    describe "#rank_index" do
      let(:rank_index) { board_square_names.rank_index(square) }
      it "is 4" do
        expect(rank_index).to eql(4)
      end
    end
  end
end
