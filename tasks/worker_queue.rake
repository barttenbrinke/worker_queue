require 'rake'
require 'rubygems'

namespace :worker_queue do

  desc 'Start the worker'
  task :work => :environment do
    worker = WorkerQueue::WorkerQueue.new
    worker.work
  end

end
