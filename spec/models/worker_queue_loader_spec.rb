require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe "When loading worker queue items" do
  before(:each) do
    @loaders_lib = File.dirname(__FILE__)+'/../loaders'

    unless Object.const_defined? 'FirstExampleLoader'
      class FirstExampleLoader < WorkerQueue::WorkerQueueItemLoader
        def self.prepare ; end
      end 
    end

    unless Object.const_defined? 'Example'
      class Example
        class SecondExampleLoader < WorkerQueue::WorkerQueueItemLoader
        end
      end
    end
  end

  it "should define loaders_lib as RAILS_ROOT/lib/worker_queue" do
    WorkerQueue.send(:loaders_lib).should == File.join( RAILS_ROOT, 'lib', 'worker_queue', '' )
  end

  it "should require loaders under loaders_lib" do
    WorkerQueue.stub!(:loaders_lib).and_return(@loaders_lib)
    FirstExampleLoader.stub!(:load)
    Example::SecondExampleLoader.stub!(:load)
    WorkerQueue.should_receive(:require).with(@loaders_lib+'/first_example_loader.rb')
    WorkerQueue.should_receive(:require).with(@loaders_lib+'/example/second_example_loader.rb')
    WorkerQueue.load
  end

  it "for each loader, should call AnyLoader.load class method" do
    WorkerQueue.stub!(:loaders_lib).and_return(@loaders_lib)
    FirstExampleLoader.should_receive(:load)
    Example::SecondExampleLoader.should_receive(:load)
    WorkerQueue.load
  end

  it "should raise error if loader does not implement class method prepare()" do
    worker_item = stub( WorkerQueue::WorkerQueueItem, { :save! => true } )
    WorkerQueue::WorkerQueueItem.stub!(:new).and_return(worker_item)
    lambda { FirstExampleLoader.load }.should_not raise_error(
      "FirstExampleLoader.prepare() MUST be implemented")
    lambda { Example::SecondExampleLoader.load }.should raise_error(
      "Example::SecondExampleLoader.prepare() MUST be implemented" )
  end

end

