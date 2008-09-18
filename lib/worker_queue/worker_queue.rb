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
  # *<tt>tasks</tt> The tasks to do work for. Defaults to self.available_tasks
  # Options
  # *<tt>:keep_binary_data</tt> Gets passed to execute. Keeps binary data after successfull execute.
  def self.work(tasks = self.available_tasks, options = {})
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
  
  # Determine the waiting tasks. Filteres out any running groups
  # *<tt>tasks</tt> The tasks to evaluate. Defaults to WorkerQueueItem.waiting_tasks
  def self.available_tasks(tasks = WorkerQueue::WorkerQueueItem.waiting_tasks)
    running_tasks   = WorkerQueue::WorkerQueueItem.busy_tasks
    running_groups  = running_tasks.collect{|x| x.task_group }.uniq.compact
    
    (tasks - running_tasks).reject{|x| running_groups.include?(x.task_group)}
  end
  
  # Are there any tasks to process?
  def self.work?
    available_tasks.length > 0
  end

  # Load the worker_queue items under <RAILS_ROOT>/lib/worker_queue
  def self.load
    Dir.glob(File.join( loaders_lib, '**', '*.rb' )).each do |file|
      require file
      file.sub(/^#{Regexp.escape(loaders_lib)}(.*)\.rb$/,'\1').classify.constantize.load
    end
  end

  # Path where worker_queue item loaders are placed
  def self.loaders_lib
    File.join( RAILS_ROOT, 'lib', 'worker_queue', '' )
  end


end
