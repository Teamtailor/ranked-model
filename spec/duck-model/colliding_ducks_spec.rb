require 'spec_helper'

describe LovesickDuck do
  before {
    @quacky = LovesickDuck.create(:name => 'Quacky')
    @feathers = LovesickDuck.create(:name => 'Feathers')
    @wingy = LovesickDuck.create(:name => 'Wingy')
    @webby = LovesickDuck.create(:name => 'Webby')
  }

  describe "a duck saved with a rank another duck already holds" do
    before {
      @others_before = LovesickDuck.where.not(:id => @webby.id).order(:row).pluck(:id, :row)
      LovesickDuck.find(@webby.id).update :row => @feathers.reload.row
    }

    it "takes the adjacent free rank" do
      expect(@webby.reload.row).to eq(@feathers.reload.row - 1)
    end

    it "leaves every other duck's rank untouched" do
      expect(LovesickDuck.where.not(:id => @webby.id).order(:row).pluck(:id, :row)).to eq(@others_before)
    end

    it "keeps all ranks unique" do
      expect(LovesickDuck.pluck(:row).uniq.size).to eq(4)
    end
  end

  describe "a duck saved with a rank whose neighbour below is taken too" do
    before {
      LovesickDuck.find(@wingy.id).update_column :row, @feathers.reload.row - 1
      LovesickDuck.find(@webby.id).update :row => @feathers.reload.row
    }

    it "falls back to rearranging and keeps all ranks unique" do
      expect(LovesickDuck.pluck(:row).uniq.size).to eq(4)
    end

    it "places the saved duck right before the duck it collided with" do
      expect(LovesickDuck.order(:row).pluck(:id)).to eq([@quacky.id, @wingy.id, @webby.id, @feathers.id])
    end
  end
end

module WritesFromAnotherProcess
  class << self
    attr_accessor :ranks
  end

  private

  def assure_unique_position
    (WritesFromAnotherProcess.ranks || []).each do |rank|
      LovesickDuck.connection.execute "INSERT INTO lovesick_ducks (name, row) VALUES ('Concurrent', #{rank})"
    end
    WritesFromAnotherProcess.ranks = nil
    super
  end
end

RankedModel::Ranker::Mapper.prepend WritesFromAnotherProcess

describe LovesickDuck do
  describe "the first duck of an empty list colliding with ducks saved by another process" do
    after { WritesFromAnotherProcess.ranks = nil }

    [:last, :first].each do |position|
      context "when positioned #{position} with the query cache on" do
        before {
          WritesFromAnotherProcess.ranks = [0, -1]
          LovesickDuck.cache { LovesickDuck.create(:name => 'Webby', :row_position => position) }
        }

        it "keeps all ranks unique" do
          expect(LovesickDuck.pluck(:row).uniq.size).to eq(3)
        end
      end
    end
  end
end
