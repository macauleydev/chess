require "./app/board"
require "./app/explore"

RSpec.describe Explore do
  describe "#en_passant_capture_square" do
    let(:board_ep_capture) { Board.new }
    subject(:ep_capture) { board_ep_capture.en_passant_capture_square(*args) }

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
