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
            square = ("a".."h").to_a.sample + ("1".."8").to_a.sample until contents[square].nil?
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
  context "when analyzing square 'c5'" do
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

    # Private method so tests are unnecessary:
    # describe "#square_at(2, 4)" do
    #   subject(:square_at) { board_square_names.square_at(*indexes) }
    #   it "is c5" do
    #     expect(square_at).to eql("c5")
    #   end
    # end
  end

  describe "#square?" do
    subject(:board_square?) { described_class.new }
    let(:square?) { board_square?.square?(square) }

    context "when a square" do
      context "h1" do
        let(:square) { "h1" }
        it "is true" do
          expect(square?).to be true
        end
      end
      context "a8" do
        let(:square) { "a8" }
        it "is true" do
          expect(square?).to be true
        end
      end
    end
    context "when not a square" do
      context "h0" do
        let(:square) { "h0" }
        it "is false" do
          expect(square?).to be false
        end
      end
      context "a9" do
        let(:square) { "a9" }
        it "is false" do
          expect(square?).to be false
        end
      end
      context "i2" do
        let(:square) { "i2" }
        it "is false" do
          expect(square?).to be false
        end
      end
      context "a3b" do
        let(:square) { "a3b" }
        it "is false" do
          expect(square?).to be false
        end
      end
    end
  end

  # # Private method so tests are unnecessary:
  # describe "#square" do
  #   subject(:board_square) { described_class.new }
  #   let(:square) { board_square.square(*args) }
  #   context "with automatic color" do
  #     context "from h2 (White) by -7, 6" do
  #       let(:args) { ["h2", -7, 6] }
  #       it "is a8" do
  #         expect(square).to eq("a8")
  #       end
  #     end
  #     context "from b1 (White) by 6, 7" do
  #       let(:args) { ["b1", 6, 7] }
  #       it "is h8" do
  #         expect(square).to eq("h8")
  #       end
  #     end
  #     context "from c7 (Black) by 5, 3" do
  #       let(:args) { ["c7", 5, 3] }
  #       it "is h4" do
  #         expect(square).to eq("h4")
  #       end
  #     end
  #     context "from f6 (empty) by -2, -1" do
  #       let(:args) { ["f6", -2, -1] }
  #       it "is d5" do
  #         expect(square).to eq("d5")
  #       end
  #     end
  #   end
  #   context "with custom color" do
  #     context "from e8 (Black) by 2, -4 White" do
  #       let(:args) { ["e8", 2, -4, White] }
  #       it "is g4" do
  #         expect(square).to eq("g4")
  #       end
  #     end
  #     context "from a4 (empty) by 0, 3 Black" do
  #       let(:args) { ["a4", 0, 3, Black] }
  #       it "is a1" do
  #         expect(square).to eq("a1")
  #       end
  #     end

  #   end
  #   context "leading off board" do
  #     context "from g2 (White) by 2, 3" do
  #       let(:args) { ["g2", 2, 3] }
  #       it "is nil" do
  #         expect(square).to be_nil
  #       end
  #     end
  #     context "from f7 (Black) by -3, 7" do
  #       let(:args) { ["f7", -3, 7] }
  #       it "is nil" do
  #         expect(square).to be_nil
  #       end
  #     end
  #   end
  # end

  # Private method so tests are unnecessary:
  # describe "#square_at" do
  #   subject(:board_square_at) { described_class.new }
  #   let(:square_at) { board_square_at.square_at(*args) }

  #   context "when in range (0..7)" do
  #     context "7, 0" do
  #       let(:args) { [7, 0] }
  #       it "is h1" do
  #         expect(square_at).to eq("h1")
  #       end
  #     end
  #     context "0, 7" do
  #       let(:args) { [0, 7] }
  #       it "is a8" do
  #         expect(square_at).to eq("a8")
  #       end
  #     end
  #     context "4, 2" do
  #       let(:args) { [4, 2] }
  #       it "is e3" do
  #         expect(square_at).to eq("e3")
  #       end
  #     end
  #   end
  #   context "when out of range" do
  #     context "8, 3" do
  #       let(:args) { [8, 3] }
  #       it "is nil" do
  #         expect(square_at).to be_nil
  #       end
  #     end
  #     context "1, 8" do
  #       let(:args) { [1, 8] }
  #       it "is nil" do
  #         expect(square_at).to be_nil
  #       end
  #     end
  #     context "-1, 2" do
  #       let(:args) { [-1, 2] }
  #       it "is nil" do
  #         expect(square_at).to be_nil
  #       end
  #     end
  #     context "4, -1" do
  #       let(:args) { [4, -1] }
  #       it "is nil" do
  #         expect(square_at).to be_nil
  #       end
  #     end
  #   end
  # end

  describe "#square_ahead" do
    subject(:board_square_ahead) { described_class.new }
    context "with default arguments" do
      let(:square_ahead_1) { board_square_ahead.square_ahead(from_square) }
      context "of h2 (White)" do
        let(:from_square) { "h2" }
        it "is h3" do
          expect(square_ahead_1).to eql("h3")
        end
      end
      context "of a7 (Black)" do
        let(:from_square) { "a7" }
        it "is a6" do
          expect(square_ahead_1).to eql("a6")
        end
      end
      context "of e5 (empty)" do
        let(:from_square) { "e5" }
        it "is e6" do
          expect(square_ahead_1).to eql("e6")
        end
      end
    end
    context "with custom argument(s)" do
      let(:square_ahead_custom) { board_square_ahead.square_ahead(*args) }
      context "of d2 (White), 2 steps" do
        let(:args) { ["d2", 2] }
        it "is d4" do
          expect(square_ahead_custom).to eql("d4")
        end
      end
      context "of g7 (Black), 2 steps" do
        let(:args) { ["g7", 2] }
        it "is g5" do
          expect(square_ahead_custom).to eql("g5")
        end
      end
      context "of d2 (White), -1 step" do
        let(:args) { ["d2", -1] }
        it "is d1" do
          expect(square_ahead_custom).to eql("d1")
        end
      end
      context "of g7 (Black), -1 step" do
        let(:args) { ["g7", -1] }
        it "is g8" do
          expect(square_ahead_custom).to eql("g8")
        end
      end
      context "of c7, 1 White step" do
        let(:args) { ["c7", 1, White] }
        it "is c8" do
          expect(square_ahead_custom).to eql("c8")
        end
      end
      context "of b5, 1 Black step" do
        let(:args) { ["b5", 1, Black] }
        it "is b4" do
          expect(square_ahead_custom).to eql("b4")
        end
      end
    end
    context "when leading off board" do
      let(:square_ahead_extreme) { board_square_ahead.square_ahead(*args) }
      context "of c1 (White), -1 step" do
        let(:args) { ["c1", -1] }
        it "is nil" do
          expect(square_ahead_extreme).to be_nil
        end
      end
      context "of d1, -1 White step" do
        let(:args) { ["d1", -1, White] }
        let(:steps) { -1 }
        let(:color) { White }
        it "is nil" do
          expect(square_ahead_extreme).to be_nil
        end
      end
      context "of h2, 2 Black steps" do
        let(:args) { ["h2", 2, Black] }
        it "is nil" do
          expect(square_ahead_extreme).to be_nil
        end
      end
    end
  end

  describe "#en_passant_capture_square" do
    subject(:board_ep_capture) { described_class.new }
    let(:ep_capture) { board_ep_capture.en_passant_capture_square(*args) }

    context "with possible e.p. attack" do
      context "g5 to h6 (White kingside)" do
        let(:args) { ["g5", "h6"] }

        it "is h5" do
          expect(ep_capture).to eql("h5")
        end
      end
      context "c4 to d3 (Black kingside)" do
        let(:args) { ["c4", "d3"] }

        it "is d4" do
          expect(ep_capture).to eql("d4")
        end
      end
      context "c4 to b3 (Black queenside)" do
        let(:args) { ["c4", "b3"] }

        it "is b4" do
          expect(ep_capture).to eql("b4")
        end
      end
    end
    context "with impossible e.p. attack" do
      context "b6 to a7 (wrong rank, White)" do
        let(:args) { %w[b6 a7] }

        it "is nil" do
          expect(ep_capture).to be_nil
        end
      end
      context "f6 to e5 (wrong rank, Black)" do
        let(:args) { %w[f6 e5] }

        it "is nil" do
          expect(ep_capture).to be_nil
        end
      end
      context "d5 to f7 (diagonal too far)" do
        let(:args) { %w[d5 f7] }

        it "is nil" do
          expect(ep_capture).to be_nil
        end
      end
      context "c5 to c6 (not diagonal)" do
        let(:args) { %w[d4 f6] }

        it "is nil" do
          expect(ep_capture).to be_nil
        end
      end
    end
  end
end
