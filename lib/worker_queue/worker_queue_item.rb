class WorkerQueue
  class WorkerQueueItem < ActiveRecord::Base
    
    named_scope :all_waiting_tasks, lambda { {:conditions => ['status = ?', STATUS_WAITING]} }
    named_scope :all_busy_tasks, lambda { {:conditions => ['status = ? OR status = ?', STATUS_RUNNING, STATUS_ERROR]} }
    
    validate :hash_in_argument_hash  
    serialize :argument_hash, Hash
    
    # Status messages
    STATUS_WAITING    = 0
    STATUS_RUNNING    = 1
    STATUS_ERROR      = 2
    STATUS_COMPLETED  = 3
  
    # Execute ourselves
    # Note that the task executed expects Class.method(args_hash, binary_blob) to return true or false.
    # Options
    # *<tt>:keep_binary_data</tt> Do not empty the binary data on completion.
    def execute(options = {})
      
      ah = self.argument_hash.clone
      ah.store(:data, self.data) if self.data

      begin
        unless class_name.classify.constantize.send(method_name.to_sym, ah)
          self.status = STATUS_ERROR
          self.error_message = "called method returned false"
        end
      rescue Exception => e
        self.status = STATUS_ERROR
        self.error_message = "class or method does not exist" + e.to_s
      end
      
      # If we have an error, do not run anything in this group (halt the chain)
      unless self.status == STATUS_ERROR
        self.status   = STATUS_COMPLETED
        self.data     = nil unless !!options[:keep_data]
      end
    end
    
    # Check if this task is running
    def running?
      self.status == STATUS_RUNNING
    end
    
    # Check if the task is completed
    def completed?
      self.status == STATUS_COMPLETED
    end
    
    # Check if we can execute ourselves
    def executable?
      
      # Return false if picked up by another WQ instance
      if self.id
        old_lock_version = self.lock_version
        self.reload
        return false if old_lock_version != self.lock_version
      end
      
      # Return true we can sill be executed
      return WorkerQueue.waiting_tasks.include?(self) && !self.completed? && !self.running?    
    end

    # Validates hash in the argument_hash attribute. If none found, a hash is inserted.
    def hash_in_argument_hash
      self.argument_hash = {} if self.argument_hash.nil?
      return true
    end
    
    # This prevents us fetching the data field for a simple status lookup
    def self.partial_select_attributes
      (WorkerQueue::WorkerQueueItem.columns.collect{|x| x.name} - ['data']).join(',')
    end

  end
end