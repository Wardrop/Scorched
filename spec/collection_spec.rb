require_relative './helper.rb'

class CollectionA
  include Scorched::Collection('middleware')
end

class CollectionB < CollectionA
end

class CollectionC < CollectionB
end

module Scorched
  describe Collection do
    it "defaults to an empty set" do
      CollectionA.middleware.should == Set.new
    end
  
    it "can be set to a given set" do
      my_set = Set.new(['horse', 'cat', 'dog'])
      CollectionA.middleware.replace my_set
      CollectionA.middleware.should == my_set
    end
    
    it "automatically converts arrays to sets" do
      array = ['horse', 'cat', 'dog']
      CollectionA.middleware.replace array
      CollectionA.middleware.should == array.to_set
    end
  
    it "recursively inherits from parents by default" do
      CollectionB.middleware.should == CollectionA.middleware
      CollectionC.middleware.should == CollectionA.middleware
    end
  
    it "allows values to be overridden without modifying the parent" do
      CollectionB.middleware << 'rabbit'
      CollectionB.middleware.should include('rabbit')
      CollectionA.middleware.should_not include('rabbit')
    end
    
    it "provides access to a copy of internal set" do
      CollectionB.middleware.to_set(false).should == Set.new(['rabbit'])
    end
  end
end