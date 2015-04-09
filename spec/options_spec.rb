require_relative './helper.rb'

class OptionsA
  include Scorched::Options('colours')
end

class OptionsB < OptionsA
end

class OptionsC < OptionsB
end

module Scorched
  describe Options do
    it "defaults to an empty hash" do
      OptionsA.colours.should be_empty
    end

    it "can be set to a given hash" do
      my_hash = {car: 'red', house: 'cream'}
      OptionsA.colours.replace my_hash
      OptionsA.colours.should == my_hash
    end

    it "recursively inherits from parents by default" do
      OptionsB.colours.should == {car: 'red', house: 'cream'}
      OptionsC.colours.should == {car: 'red', house: 'cream'}
    end

    it "allows values to be overridden without modifying the parent" do
      OptionsB.colours[:car] = 'blue'
      OptionsB.colours[:car].should == 'blue'
      OptionsA.colours[:car].should == 'red'
    end
    
    it "provides access to a copy of internal hash" do
      OptionsB.colours.to_hash(false).should == {car: 'blue'}
      OptionsC.colours.to_hash(false).should == {}
      OptionsC.colours.to_hash(false).object_id.should_not == OptionsC.colours.object_id
    end
  end
end