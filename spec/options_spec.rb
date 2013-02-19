require_relative './helper.rb'

class OptionsA
  include Scorched::Options('conditions')
end

class OptionsB < OptionsA
end

class OptionsC < OptionsB
end

module Scorched
  describe Options do
    it "defaults to an empty hash" do
      OptionsA.conditions.should be_empty
    end

    it "can be set to a given hash" do
      my_hash = {car: 'red', house: 'cream'}
      OptionsA.conditions << my_hash
      OptionsA.conditions.should == my_hash
    end

    it "inherits recursively from parents" do
      OptionsC.conditions.should == {car: 'red', house: 'cream'}
      OptionsC.conditions[:car].should == 'red'
      OptionsC.conditions.local_hash.should == {}
    end

    it "overrides parent, but does not overwrite" do
      OptionsB.conditions[:car] = 'blue'
      OptionsB.conditions[:car].should == 'blue'
      OptionsA.conditions[:car].should == 'red'
    end

    it "sets options on the expected class regardless of inheritance" do
      OptionsB.conditions[:boat] = 'white'
      OptionsA.conditions[:boat].should be_nil
    end
  end
end