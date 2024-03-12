require "./app/grid"

RSpec.describe Grid do
  let(:dummy_class) { Class.new { extend Grid } }

  describe "#square?" do
    let(:square?) { dummy_class.square?(square) }

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

  context "when analyzing square 'c5'" do
    let(:square) { "c5" }

    describe "#file_letter" do
      subject(:file_letter) { dummy_class.file_letter(square) }
      it "is the String c" do
        expect(file_letter).to eql("c")
      end
    end

    describe "#rank_number" do
      subject(:rank_number) { dummy_class.rank_number(square) }
      it "is the Integer 5" do
        expect(rank_number).to eql(5)
      end
    end

    describe "#file_index" do
      subject(:file_index) { dummy_class.file_index(square) }
      it "is 2" do
        expect(file_index).to eql(2)
      end
    end

    describe "#rank_index" do
      subject(:rank_index) { dummy_class.rank_index(square) }
      it "is 4" do
        expect(rank_index).to eql(4)
      end
    end
  end
end
