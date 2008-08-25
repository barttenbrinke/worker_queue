# Bart ten Brinke - Nedap healthcare - 2008
#
# Usage:
# work = WorkerQueue::WorkerQueueItem.new
# work.class_name     = 'Someclass'
# work.method_name    = 'somemethod'
# work.argument_hash  = {:monkey => :tail}
# work.binary_data    = nil
# work.save!
#
# This will be picked up by the worker when the following command is called:
# WorkerQueue.work
class WorkerQueue  
  # Do work
  # *<tt>tasks</tt> The tasks to do work for. Defaults to self.waiting_tasks
  # Options
  # *<tt>:keep_binary_data</tt> Gets passed to execute. Keeps binary data after successfull execute.
  def self.work(tasks = self.waiting_tasks, options = {})
    tasks.each do |task|
      
      # Start off by flagging the task as running.
      begin
        # Check if we are still allowed to do this task
        next unless task.executable?      
        task.status = WorkerQueue::WorkerQueueItem::STATUS_RUNNING
        task.save!
      rescue ActiveRecord::StaleObjectError
        # The task has changed, so it was probably picked up by some other worker.
        # Skip to the next task
        next
      end
  
      # Run the task and save
      task.execute(options)
      task.save!
    end
  end
  
  # Determine the waiting tasks. Filteres out the running groups
  # *<tt>tasks</tt> The tasks to evaluate. Defaults to self.uncompleted_tasks
  def self.waiting_tasks(tasks = self.all_waiting_tasks)
    running_tasks   = self.all_busy_tasks
    running_groups  = running_tasks.collect{|x| x.task_group}.uniq
    
    (tasks - running_tasks).reject{|x| running_groups.include?(x.task_group)}
  end
  
  # Are there any tasks to process?
  def self.work?
    waiting_tasks.length > 0
  end

  # Find tasks with a certain flag uncompleted tasks in the database
  def self.all_waiting_tasks
    WorkerQueue::WorkerQueueItem.all_waiting_tasks(
      :order => 'id',
      :select => WorkerQueue::WorkerQueueItem.partial_select_attributes
    )
  end

  # Find all tasks being worked on at the moment.
  def self.all_busy_tasks
    WorkerQueue::WorkerQueueItem.all_busy_tasks(
      :order => 'id',
      :select => WorkerQueue::WorkerQueueItem.partial_select_attributes
    )
  end
  
end