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
    context "default" do
      it "defaults to an empty array" do
        CollectionA.middleware.should == []
      end
    
      it "can be set to a given hash" do
        my_array = ['horse', 'cat', 'dog']
        CollectionA.middleware = my_array
        CollectionA.middleware.should == my_array
      end
    
      it "inherits options of superclass by default" do
        CollectionB.middleware.should == ['horse', 'cat', 'dog']
        CollectionB.middleware(false).should == []
      end
    
      it "inherits recursively" do
        CollectionC.middleware.should == CollectionA.middleware
      end
    
      it "overrides parent, without modifying it" do
        CollectionB.middleware(false) << 'rabbit'
        CollectionB.middleware.should include('rabbit')
        CollectionA.middleware.should_not include('rabbit')
      end

      it "pushes new values onto the expected target" do
        collection = CollectionB.middleware
        collection << 'squeak'
        collection.should include('squeak') # Ensure the 'merged' options also reflect the change.
        CollectionA.middleware.should_not include('squeak')
      end
    end
  end
end