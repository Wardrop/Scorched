require_relative './helper.rb'

class OptionsA
  include Scorched::Options
  include Scorched::Options('conditions')
end

class OptionsB < OptionsA
end

class OptionsC < OptionsB
end

module Scorched
  describe Options do
    context "default" do
      it "defaults to an empty hash" do
        OptionsA.options.should == {}
      end
    
      it "can be set to a given hash" do
        my_hash = {dog: 'roof', cat: 'meow'}
        OptionsA.options = my_hash
        OptionsA.options.should == my_hash
      end
    
      it "inherits options of superclass by default" do
        OptionsB.options.should == {dog: 'roof', cat: 'meow'}
        OptionsB.options(false).should == {}
      end
    
      it "inherits recursively" do
        OptionsC.options.should == OptionsA.options
      end
    
      it "overrides parent, but does not overwrite" do
        OptionsB.options(false)[:dog] = 'bark'
        OptionsB.options[:dog].should == 'bark'
        OptionsA.options[:dog].should == 'roof'
      end

      it "sets options on the expected target" do
        opts = OptionsB.options
        opts[:mouse] = 'squeak'
        opts[:mouse].should == 'squeak' # Ensure the 'merged' options also reflect the change.
        OptionsA.options[:mouse].should be_nil
      end
    end
    
    context "included with different accessor name" do
      it "defaults to an empty hash" do
        OptionsA.conditions.should == {}
      end

      it "can be set to a given hash" do
        my_hash = {car: 'red', house: 'cream'}
        OptionsA.conditions = my_hash
        OptionsA.conditions.should == my_hash
      end

      it "inherits options of superclass by default" do
        OptionsB.conditions.should == {car: 'red', house: 'cream'}
        OptionsB.conditions(false).should == {}
      end

      it "inherits recursively" do
        OptionsC.conditions.should == OptionsA.conditions
      end

      it "overrides parent, but does not overwrite" do
        OptionsB.conditions(false)[:car] = 'blue'
        OptionsB.conditions[:car].should == 'blue'
        OptionsA.conditions[:car].should == 'red'
      end

      it "sets options on the expected class regardless of inheritance" do
        OptionsB.conditions[:boat] = 'white'
        OptionsA.conditions[:boat].should be_nil
      end
    end
  end
end