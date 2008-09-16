class WorkerQueue
  class WorkerQueueItem < ActiveRecord::Base
    
    # Status messages
    STATUS_WAITING    = 0
    STATUS_RUNNING    = 1
    STATUS_ERROR      = 2
    STATUS_COMPLETED  = 3
    STATUS_SKIPPED    = 4 

    named_scope :waiting,
      lambda {{ :conditions => {:status => STATUS_WAITING} }}
    named_scope :running,
      lambda {{ :conditions => {:status => STATUS_RUNNING} }}
    named_scope :errors,
      lambda {{ :conditions => {:status => STATUS_ERROR} }}
    named_scope :completed,
      lambda {{ :conditions => {:status => STATUS_COMPLETED} }}
    named_scope :busy,
      lambda { {:conditions => ['status = ? OR status = ?', STATUS_RUNNING, STATUS_ERROR]} }
    
    validate :hash_in_argument_hash  
    serialize :argument_hash, Hash
    
    # Execute ourselves
    # Note that the task executed expects Class.method(args_hash, binary_blob) to return true or false.
    # Options
    # *<tt>:keep_data</tt> Do not empty the data on completion.
    # *<tt>:skip_on_error</tt> Do not stop the execution of a group when an error was encountered.
    def execute(options = {})
      
      ah = argument_hash.clone
      ah.store(:data, data) if data

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
      if error?
        self.status   = STATUS_SKIPPED if options[:skip_on_error]
      else
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
    
    def error?
      self.status == STATUS_ERROR
    end
    
    # Check if we can execute ourselves
    def executable?
      
      # Return false if picked up by another WQ instance
      if id
        old_lock_version = lock_version
        self.reload
        return false if old_lock_version != lock_version
      end
      
      # Return true we can sill be executed
      return WorkerQueue.available_tasks.include?(self) && !completed? && !running?    
    end

    # Validates hash in the argument_hash attribute. If none found, a hash is inserted.
    def hash_in_argument_hash
      argument_hash = {} if argument_hash.nil?
      return true
    end
    
    # Class methods
    
    # This prevents us fetching the data field for a simple status lookup
    def self.partial_select_attributes
      (columns.collect{|x| x.name} - ['data']).join(',')
    end

    # Find tasks with a certain flag uncompleted tasks in the database
    def self.waiting_tasks
      waiting(:order => 'id', :select => partial_select_attributes)
    end

    # Find all tasks being worked on at the moment.
    def self.busy_tasks
      busy(:order => 'id', :select => partial_select_attributes)
    end

  end
end