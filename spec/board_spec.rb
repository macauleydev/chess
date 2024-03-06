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

      it "sets no pieces on ranks 3,4,5,6" do
        rank_3456_squares = (3..6).flat_map { |r| squares_in_rank[r] }
        rank_3456_contents = contents.values_at(*rank_3456_squares)
        expect(rank_3456_contents).to all(be_nil)
      end
    end
    context "when random contents are given" do
      subject(:board_random_contents) { described_class.new(contents: given_contents) }
      let(:given_contents) do
        contents = {}
        [White, Black].each do |color|
          Piece.subclasses.each do |piece_type|
            square = ("a".."h").to_a.shuffle.first + ("1".."8").to_a.shuffle.first until contents[square].nil?
            contents[square] = piece_type.new(color, [square])
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
  context "when analyzing square 'c5' (file index 2, rank index 4)" do
    subject(:board_square_names) { described_class.new }
    let(:square) { "c5" }
    let(:indexes) { [2, 4] }

    describe "#file_letter" do
      subject(:file_letter) { board_square_names.file_letter(square) }
      it "is the String c" do
        expect(file_letter).to eql("c")
      end
    end

    describe "#rank_number" do
      subject(:rank_number) { board_square_names.rank_number(square) }
      it "is the Integer 5" do
        expect(rank_number).to eql(5)
      end
    end

    describe "#file_index" do
      subject(:file_index) { board_square_names.file_index(square) }
      it "is 2" do
        expect(file_index).to eql(2)
      end
    end

    describe "#rank_index" do
      subject(:rank_index) { board_square_names.rank_index(square) }
      it "is 4" do
        expect(rank_index).to eql(4)
      end
    end

    describe "#file_rank_index" do
      subject(:file_rank_index) { board_square_names.file_rank_index(square) }
      it "is [2, 4]" do
        expect(file_rank_index).to eql([2, 4])
      end
    end

    describe "#square_at(2, 4)" do
      subject(:square_at) { board_square_names.square_at(*indexes)}
      it "is c5" do
        expect(square_at).to eql("c5")
      end
    end
  end

  describe "#square_forward" do
    subject(:board_square_forward) { described_class.new }
    context "with default arguments" do
      let(:square_forward_1) { board_square_forward.square_forward(from_square) }
      context "1 step from h2 (White)" do
        let(:from_square) { "h2" }
        it "is h3" do
          expect(square_forward_1).to eql("h3")
        end
      end
      context "1 step from a7 (Black)" do
        let(:from_square) { "a7" }
        it "is a6" do
          expect(square_forward_1).to eql("a6")
        end
      end
      context "1 step from e5 (empty)" do
        let(:from_square) { "e5" }
        it "is e6" do
          expect(square_forward_1).to eql("e6")
        end
      end
    end
    context "with custom arguments" do
      let(:square_forward_custom) { board_square_forward.square_forward(*args) }
      context "2 steps from d2 (White)" do
        let(:args) { ["d2", 2] }
        it "is d4" do
          expect(square_forward_custom).to eql("d4")
        end
      end
      context "2 steps from g7 (Black)" do
        let(:args) { ["g7", 2] }
        it "is g5" do
          expect(square_forward_custom).to eql("g5")
        end
      end
      context "-1 step from d2 (White)" do
        let(:args) { ["d2", -1] }
        it "is d1" do
          expect(square_forward_custom).to eql("d1")
        end
      end
      context "-1 step from g7 (Black)" do
        let(:args) { ["g7", -1] }
        it "is g8" do
          expect(square_forward_custom).to eql("g8")
        end
      end
      context "-1 step from c1 (White)" do
        let(:args) { ["c1", -1] }
        it "is nil" do
          expect(square_forward_custom).to be_nil
        end
      end
      context "1 White step from c7" do
        let(:args) { ["c7", 1, White] }
        it "is c8" do
          expect(square_forward_custom).to eql("c8")
        end
      end
      context "-1 White step from d1" do
        let(:args) { ["d1", -1, White] }
        let(:steps) { -1 }
        let(:color) { White }
        it "is nil" do
          expect(square_forward_custom).to be_nil
        end
      end
      context "2 Black steps from h2" do
        let(:args) { ["h2", 2, Black] }
        it "is nil" do
          expect(square_forward_custom).to be_nil
        end
      end
      context "1 Black step from b5" do
        let(:args) { ["b5", 1, Black] }
        it "is b4" do
          expect(square_forward_custom).to eql("b4")
        end
      end
    end
  end

  describe "#en_passant_capture_square" do
    subject(:board_ep_capture) { described_class.new }
    let(:ep_capture) { board_ep_capture.en_passant_capture_square(*args) }

    context "with possible e.p. attack" do
      context "g5 to h6 (White rightward)" do
        let(:args) { ["g5", "h6"] }

        it "is h5" do
          expect(ep_capture).to eql("h5")
        end
      end
      context "c4 to d3 (Black rightward)" do
        let(:args) { ["c4", "d3"] }

        it "is d4" do
          expect(ep_capture).to eql("d4")
        end
      end
      context "c4 to b3 (Black leftward)" do
        let(:args) { ["c4", "b3"] }

        it "is b4" do
          expect(ep_capture).to eql("b4")
        end
      end
    end
    context "with impossible e.p. attack" do
      context "b6 to a7 (White wrong rank)" do
        let(:args) { %w[b6 a7] }

        it "is nil" do
          expect(ep_capture).to be_nil
        end
      end
      context "f6 to e5 (Black wrong rank)" do
        let(:args) { %w[f6 e5] }

        it "is nil" do
          expect(ep_capture).to be_nil
        end
      end
      context "d5 to f7 (2 steps diagonal)" do
        let(:args) { %w[d5 f7] }

        it "is nil" do
          expect(ep_capture).to be_nil
        end
      end
      context "c5 to c6 (1 step straight)" do
        let(:args) { %w[d4 f6] }

        it "is nil" do
          expect(ep_capture).to be_nil
        end
      end
    end
  end
end
