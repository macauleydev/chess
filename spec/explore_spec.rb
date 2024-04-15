require "./app/board"
require "./app/explore"
require "./app/piece"

RSpec.describe Explore do
  describe "#en_passant_capture_square" do
    subject(:ep_capture) { board_ep_capture.en_passant_capture_square(*args) }

    let(:board_ep_capture) { Board.new }

    context "when g5 to h6 (White kingside e.p.)" do
      let(:args) { ["g5", "h6"] }

      it "is h5" do
        expect(ep_capture).to eql("h5")
      end
    end

    context "when c4 to d3 (Black kingside e.p.)" do
      let(:args) { ["c4", "d3"] }

      it "is d4" do
        expect(ep_capture).to eql("d4")
      end
    end

    context "when c4 to b3 (Black queenside e.p.)" do
      let(:args) { ["c4", "b3"] }

      it "is b4" do
        expect(ep_capture).to eql("b4")
      end
    end

    context "when b6 to a7 (White wrong rank)" do
      let(:args) { %w[b6 a7] }

      it "is nil" do
        expect(ep_capture).to be_nil
      end
    end

    context "when f6 to e5 (Black wrong rank)" do
      let(:args) { %w[f6 e5] }

      it "is nil" do
        expect(ep_capture).to be_nil
      end
    end

    context "when d5 to f7 (diagonal too far)" do
      let(:args) { %w[d5 f7] }

      it "is nil" do
        expect(ep_capture).to be_nil
      end
    end

    context "when c5 to c6 (not diagonal)" do
      let(:args) { %w[d4 f6] }

      it "is nil" do
        expect(ep_capture).to be_nil
      end
    end
  end

  describe "#kings_square" do
    context "with kings unmoved" do
      subject(:kings_square_unmoved) { board_kings_square_unmoved.kings_square(color) }

      let(:board_kings_square_unmoved) { Board.new }

      context "when White" do # rubocop:disable RSpec/NestedGroups
        let(:color) { White }

        it "is e1" do
          expect(kings_square_unmoved).to eql("e1")
        end
      end

      context "when Black" do # rubocop:disable RSpec/NestedGroups
        let(:color) { Black }

        it "is e8" do
          expect(kings_square_unmoved).to eql("e8")
        end
      end
    end

    context "with kings moved (White on g2, Black on c8)" do
      subject(:kings_square_moved) { board_kings_square_moved.kings_square(color) }

      let(:board_kings_square_moved) { Board.new(contents: moved_kings) }
      let(:board_stub) { double(Board) }
      let(:moved_kings) {
        {"g2" => King.new(White, board_stub, ["g2"]),
        "c8" => King.new(Black, board_stub, ["c8"])}
      }

      context "when White" do # rubocop:disable RSpec/NestedGroups

        let(:color) { White }

        it "is g2" do
          expect(kings_square_moved).to eql("g2")
        end
      end

      context "when Black" do # rubocop:disable RSpec/NestedGroups
        let(:color) { Black }

        it "is c8" do
          expect(kings_square_moved).to eql("c8")
        end
      end
    end
  end
end
