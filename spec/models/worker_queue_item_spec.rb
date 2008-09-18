require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe "waiting tasks" do
  before(:each) do
    WorkerQueue::WorkerQueueItem.destroy_all
    
    @item = WorkerQueue::WorkerQueueItem.new
    @worker_queue = []
    
    1.upto(10) do |number|
      @item2 = @item.clone
      @item2.task_name      = number.to_s
      @item2.task_group     = 'some_group'
      @item2.status         = WorkerQueue::WorkerQueueItem::STATUS_WAITING

      @item2.class_name     = 'WorkerTester'
      @item2.method_name    = 'process'
      @item2.argument_hash  = {:aap => :noot}
      @item2.data           = '123456789'
      @item2.save
      
      @worker_queue << @item2
    end

  end

  it "should not crash on an empty set" do
    WorkerQueue::WorkerQueueItem.destroy_all
    WorkerQueue.available_tasks([]).should eql([])
  end

  it "should find all waiting tasks" do
    WorkerQueue.available_tasks.length.should eql(10)
  end

  it "should filter out all running tasks of the same type" do
    @worker_queue[0].task_group = 'other_group'
    @worker_queue[1].task_group = 'other_group'
    @worker_queue[1].status = WorkerQueue::WorkerQueueItem::STATUS_RUNNING
    
    @worker_queue[0].save
    @worker_queue[1].save
    
    WorkerQueue.available_tasks.length.should eql(8)
  end

  it "should filter out all running tasks is they are all the same type" do
    @worker_queue[0].status = WorkerQueue::WorkerQueueItem::STATUS_RUNNING
    @worker_queue[0].save
    
    WorkerQueue.available_tasks.length.should eql(0)
  end

  it "should order all waiting tasks in the correct order" do
    @worker_queue[0].task_group = 'other_group'
    @worker_queue[1].task_group = 'other_group'
    @worker_queue[1].status = WorkerQueue::WorkerQueueItem::STATUS_WAITING

    queue = WorkerQueue.available_tasks
    1.upto(6) do |number|
      queue[number].id.should > queue[number-1].id
    end
  end

  it "for all without specified type, should always be available" do
    @worker_queue.each { |item| item.update_attribute( :task_group, '' ) }
    @worker_queue[0].status = WorkerQueue::WorkerQueueItem::STATUS_RUNNING
    @worker_queue[0].save
    WorkerQueue.available_tasks.length.should eql(9)
  end

end

describe "work" do
  before(:each) do
    WorkerQueue::WorkerQueueItem.destroy_all
    
    @item = WorkerQueue::WorkerQueueItem.new
    @worker_queue = []
    
    1.upto(10) do |number|
      @item2 = @item.clone
      @item2.task_name      = number.to_s
      @item2.task_group     = 'some_group'
      @item2.status         = WorkerQueue::WorkerQueueItem::STATUS_WAITING

      @item2.class_name     = 'WorkerQueue::WorkerTester'
      @item2.method_name    = 'test'
      @item2.argument_hash  = {:aap => :noot}
      @item2.data           = '123456789'
      @item2.save
      
      @worker_queue << @item2
    end
    
  end
  
  it "should perform all tasks" do
    WorkerQueue::WorkerTester.should_receive(:test).with({:aap => :noot, :data => '123456789'}).exactly(10).times.and_return(true)
    WorkerQueue.work
  end
  
  it "should flag all tasks as completed" do
    WorkerQueue.work

    tasks = WorkerQueue::WorkerQueueItem.find(:all)
    tasks.length.should eql(10)

    tasks.each do |task|
      task.should be_completed
      task.should_not be_running
    end    
  end
  
  it "should handle no method errors" do
    @worker_queue[0].method_name = 'does_not_exist'
    @worker_queue[0].save
    WorkerQueue.work
    
    tasks = WorkerQueue::WorkerQueueItem.errors
    tasks.length.should eql(1)

    tasks[0].error_message.should_not be_nil
  end

  it "should handle no class errors" do
    @worker_queue[0].class_name = 'does_not_exist'
    @worker_queue[0].save
    WorkerQueue.work
    
    tasks = WorkerQueue::WorkerQueueItem.errors
    tasks.length.should eql(1)

    tasks[0].error_message.should_not be_nil
  end

  it "should handle return false from method call and stop the group execution" do
    WorkerQueue::WorkerTester.stub!(:test).and_return(false)
    WorkerQueue.work

    tasks = WorkerQueue::WorkerQueueItem.errors
    tasks.length.should eql(1)
    tasks[0].error_message.should_not be_nil

    tasks = WorkerQueue::WorkerQueueItem.waiting
    tasks.length.should eql(9)
    
    # No remainder of the group should be executable.
    WorkerQueue.available_tasks.length.should eql(0)
  end
  
end

describe "work?" do
  before(:each) do
    WorkerQueue::WorkerQueueItem.destroy_all
    
    @item = WorkerQueue::WorkerQueueItem.new
    @item.task_name      = '1234567890'
    @item.task_group     = 'some_group'
    @item.status         = WorkerQueue::WorkerQueueItem::STATUS_WAITING

    @item.class_name     = 'WorkerQueue::WorkerTester'
    @item.method_name    = 'test'
    @item.argument_hash  = {:aap => :noot}
    @item.data           = '1234567890'
    @item.save!
  end

  it "should see work" do
    WorkerQueue.should be_work
  end

  it "should not see work if an item has an error status" do
    @item.status = WorkerQueue::WorkerQueueItem::STATUS_ERROR
    @item.save
    WorkerQueue.should_not be_work
  end

  it "should not see work if item is running" do
    @item.status = WorkerQueue::WorkerQueueItem::STATUS_RUNNING
    @item.save
    WorkerQueue.should_not be_work
  end

  it "should not see work if item is running and item of the same group is waiting" do
    @item2 = @item.clone
    @item2.save

    @item.status = WorkerQueue::WorkerQueueItem::STATUS_RUNNING
    @item.save
    
    WorkerQueue.should_not be_work
  end

end

describe "When handling racing conditions" do
  before(:each) do
    WorkerQueue::WorkerQueueItem.destroy_all
    
    @item = WorkerQueue::WorkerQueueItem.new
    @item.task_name      = '1234567890'
    @item.task_group     = 'some_group'
    @item.status         = WorkerQueue::WorkerQueueItem::STATUS_RUNNING

    @item.class_name     = 'WorkerQueue::WorkerTester'
    @item.method_name    = 'test'
    @item.argument_hash  = {:aap => :noot}
    @item.data           = '1234567890'
    @item.lock_version   = 1
    @item.save!
  end

  it "should not execute an executing object" do
    WorkerQueue::WorkerTester.should_receive(:test).exactly(0).times

    @item.lock_version = 0
    @item.status = WorkerQueue::WorkerQueueItem::STATUS_WAITING
    
    WorkerQueue.work([@item])
    @item.reload
    @item.status.should eql(WorkerQueue::WorkerQueueItem::STATUS_RUNNING)
  end

  it "should not execute when the object when it is stale" do
    WorkerQueue::WorkerTester.should_receive(:test).exactly(0).times

    @item.lock_version = 0
    @item.status = WorkerQueue::WorkerQueueItem::STATUS_WAITING
    @item.stub!(:executable?).and_return(true)

    WorkerQueue.work([@item])
    @item.reload
    @item.status.should eql(WorkerQueue::WorkerQueueItem::STATUS_RUNNING)
  end
end
