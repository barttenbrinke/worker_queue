# $Id: NgTzeYang [nineone@singnet.com.sg] 11 Sep 2008 15:48 $
#
# Intended to be inherited by all work loaders. Usage:
#
# class UpdateSessionTicket < WorkerQueue::WorkerQueueItemLoader
#   def self.prepare
#     work.class_name     = 'SessionTicket'
#     work.method_name    = 'estimate_logout_timing'
#     work.argument_hash  = { :arg1 => 'value1', :arg2 => 'value2' }
#     work.binary_data    = nil
#   end
# end
#
# All loaders should be placed under <RAILS_ROOT>/lib/worker_queue dir, and the 
# name should be class_name.to_s.underscore + ".rb" (eg. update_session_ticket.rb).
#

class WorkerQueue
  class WorkerQueueItemLoader

    def self.inherited(subclass)
      subclass.class_eval do
        class << subclass
          attr_accessor :work
        end
      end
    end
    
    public

      def self.load
        self.work = WorkerQueue::WorkerQueueItem.new
        prepare
        self.work.save!
      end

    protected

      def self.prepare
        raise "Subclass MUST implement prepare()"
      end

  end
end

# __END__
