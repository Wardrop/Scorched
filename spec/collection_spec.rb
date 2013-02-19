require_relative './helper.rb'

class CollectionA
  include Scorched::Collection('middleware')
end

class CollectionB < CollectionA
end

class CollectionC < CollectionB
end

module Scorched
  describe :Collection do
    it "defaults to an empty set" do
      CollectionA.middleware.should == Set.new
    end
  
    it "can be set to a given set" do
      my_set = Set.new(['horse', 'cat', 'dog'])
      CollectionA.middleware = my_set
      CollectionA.middleware.should == my_set
    end
    
    it "automatically converts arrays to sets" do
      array = ['horse', 'cat', 'dog']
      CollectionA.middleware = array
      CollectionA.middleware.should == array.to_set
    end
  
    it "can recursively inherit options of superclass" do
      CollectionB.middleware(true).should == Set.new(['horse', 'cat', 'dog'])
      CollectionC.superclass.middleware(true)
      CollectionC.middleware(true).should == CollectionA.middleware
      CollectionB.middleware.should == Set.new
    end
  
    it "never modifies the parent" do
      CollectionB.middleware << 'rabbit'
      CollectionB.middleware.should include('rabbit')
      CollectionA.middleware.should_not include('rabbit')
    end
  end
end