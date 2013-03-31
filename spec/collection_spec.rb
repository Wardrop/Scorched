require_relative './helper.rb'

class CollectionA
  include Scorched::Collection('things')
end

class CollectionB < CollectionA
end

class CollectionC < CollectionB
end

module Scorched
  describe Collection do
    before(:each) do
      CollectionA.things.clear
      CollectionB.things.clear
      CollectionC.things.clear
    end
    
    it "defaults to an empty set" do
      CollectionA.things.should == Set.new
    end
  
    it "can be set to a given set" do
      my_set = Set.new(['horse', 'cat', 'dog'])
      CollectionA.things.replace my_set
      CollectionA.things.should == my_set
    end
    
    it "automatically converts arrays to sets" do
      array = ['small', 'medium', 'large']
      CollectionA.things.replace array
      CollectionA.things.should == array.to_set
    end
  
    it "recursively inherits from parents by default" do
      CollectionB.things.should == CollectionA.things
      CollectionC.things.should == CollectionA.things
    end
  
    it "allows values to be overridden without modifying the parent" do
      CollectionB.things << 'rabbit'
      CollectionB.things.should include('rabbit')
      CollectionA.things.should_not include('rabbit')
    end
    
    it "prepends parent values by default" do
      CollectionA.things.replace %w{car house}
      CollectionB.things.replace %w{dog cat}
      CollectionB.things.to_a.should == %w{car house dog cat}
    end
    
    it "can be set to append parent values" do
      CollectionB.things.append_parent = true
      CollectionA.things.replace %w{car house}
      CollectionB.things.replace %w{dog cat}
      CollectionB.things.to_a.should == %w{dog cat car house}
    end
    
    it "provides access to a copy of internal set" do
      CollectionA.things << 'monkey'
      CollectionB.things << 'rabbit'
      CollectionB.things.to_set(false).should == Set.new(['rabbit'])
    end
  end
end