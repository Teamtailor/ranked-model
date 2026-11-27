require 'spec_helper'

describe LovesickDuck do
  describe "appending past ducks a few ranks from the end of the range" do
    [2, 3, 4].each do |gap|
      [:last, :first].each do |position|
        context "when the end duck is #{gap} from the #{position} end" do
          before {
            end_rank = position == :last ? RankedModel::MAX_RANK_VALUE - gap : RankedModel::MIN_RANK_VALUE + gap
            step = position == :last ? -1000 : 1000
            @ducks = Array.new(3) { |i| LovesickDuck.create(:name => "Duck #{i}") }
            @ducks.reverse.each_with_index { |duck, i| LovesickDuck.where(:id => duck.id).update_all(:row => end_rank + step * i) }
            @added = Array.new(3) { |i| LovesickDuck.create(:name => "Added #{i}", :row_position => position) }
          }

          it "places each new duck past the one before it" do
            expected = position == :last ? @ducks + @added : @added.reverse + @ducks.reverse
            expect(LovesickDuck.order(:row).pluck(:id)).to eq(expected.map(&:id))
          end
        end
      end
    end
  end
end

describe LovesickDuck do
  before {
    @ducks = {
      :quacky => LovesickDuck.create(:name => 'Quacky'),
      :feathers => LovesickDuck.create(:name => 'Feathers'),
      :wingy => LovesickDuck.create(:name => 'Wingy'),
      :webby => LovesickDuck.create(:name => 'Webby'),
      :waddly => LovesickDuck.create(:name => 'Waddly'),
      :beaky => LovesickDuck.create(:name => 'Beaky')
    }
    @ducks.each { |name, duck|
      duck.reload
      duck.update :row_position => 0
      duck.save!
    }
    @ducks.each {|name, duck| duck.reload }
  }

  describe "when placing duck first" do

    describe "when enough room" do
      before {
        [:quacky, :feathers, :wingy, :webby, :waddly, :beaky].each_with_index do |name, i|
          LovesickDuck.where(id: @ducks[name].id).update_all(row: i * 1000)
          @ducks[name].reload
        end
      }

      it "first duck keeps the right distance" do
        expect {
          LovesickDuck.find_by(id: @ducks[:webby]).update!(row_position: :first)
        }.to change{ @ducks[:webby].reload.row }

        expect((@ducks[:webby].row - @ducks[:quacky].reload.row).abs).to be(1000)
      end
    end

    describe "when not enough spread room" do

      let(:available_room) { 1500 }

      before {
        [:quacky, :feathers, :wingy, :webby, :waddly, :beaky].each_with_index do |name, i|
          LovesickDuck.where(id: @ducks[name].id).update_all(row: RankedModel::MIN_RANK_VALUE + (i * 1000) + available_room)
          @ducks[name].reload
        end
      }

      it "first duck getting closer" do
        LovesickDuck.find_by(id: @ducks[:webby]).update!(row_position: :first)

        @ducks[:webby].reload
        @ducks[:quacky].reload

        expect((@ducks[:webby].row - @ducks[:quacky].row).abs).to eq(available_room * 0.3)
      end
    end

    describe "when rebalancing occurs" do
      before {
        [:quacky, :feathers, :wingy, :webby, :waddly, :beaky].each_with_index do |name, i|
          LovesickDuck.where(id: @ducks[name].id).update_all(row: RankedModel::MIN_RANK_VALUE + i)
          @ducks[name].reload
        end
      }

      it "all ducks spreads at a comfortable distance" do
        LovesickDuck.find_by(id: @ducks[:beaky]).update!(row_position: :first)
        [:quacky, :feathers, :wingy, :webby, :waddly, :beaky].each do |name|
          @ducks[name].reload
        end

        expect((@ducks[:beaky].row - @ducks[:quacky].row).abs).to eq(1000)
        expect((@ducks[:feathers].row - @ducks[:wingy].row).abs).to eq(1000)
        expect((@ducks[:webby].row - @ducks[:waddly].row).abs).to eq(1000)
      end
    end
  end

  describe "when placing duck last" do

    describe "when enough room" do
      before {
        [:quacky, :feathers, :wingy, :webby, :waddly, :beaky].each_with_index do |name, i|
          LovesickDuck.where(id: @ducks[name].id).update_all(row: i * 1000)
          @ducks[name].reload
        end
      }

      it "last duck keeps the right distance" do
        expect {
          LovesickDuck.find_by(id: @ducks[:webby]).update!(row_position: :last)
        }.to change{ @ducks[:webby].reload.row }

        expect(@ducks[:webby].row - @ducks[:beaky].reload.row).to be(1000)
      end
    end

    describe "when not enough spread room" do

      let(:available_room) { 1500 }

      before {
        [:quacky, :feathers, :wingy, :webby, :waddly, :beaky].each_with_index do |name, i|
          LovesickDuck.where(id: @ducks[name].id).update_all(row: RankedModel::MAX_RANK_VALUE - (i * 1000) - available_room)
          @ducks[name].reload
        end
      }

      it "first duck getting closer" do
        LovesickDuck.find_by(id: @ducks[:webby]).update!(row_position: :last)

        @ducks[:webby].reload
        @ducks[:quacky].reload

        expect((@ducks[:webby].row - @ducks[:quacky].row).abs).to eq(available_room * 0.3)
      end
    end

    describe "when rebalancing occurs" do
      before {
        [:quacky, :feathers, :wingy, :webby, :waddly, :beaky].each_with_index do |name, i|
          LovesickDuck.where(id: @ducks[name].id).update_all(row: RankedModel::MAX_RANK_VALUE - i)
          @ducks[name].reload
        end
      }

      it "all ducks spreads at a comfortable distance" do
        LovesickDuck.find_by(id: @ducks[:beaky]).update!(row_position: :last)
        [:quacky, :feathers, :wingy, :webby, :waddly, :beaky].each do |name|
          @ducks[name].reload
        end

        expect((@ducks[:beaky].row - @ducks[:quacky].row).abs).to eq(1000)
        expect((@ducks[:feathers].row - @ducks[:wingy].row).abs).to eq(1000)
        expect((@ducks[:webby].row - @ducks[:waddly].row).abs).to eq(1000)
      end
    end
  end
end
