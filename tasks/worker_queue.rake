require 'rake'
require 'rubygems'

def worker_queue_loaders

end

namespace :worker_queue do

  desc 'Load worker items'
  task :load => :environment do
    WorkerQueue::WorkerQueue.load
  end

  desc 'Load worker items and start the worker'
  task :load_and_work => [ :load, :work ] do ; end

  desc 'Start the worker'
  task :work => :environment do
    WorkerQueue::WorkerQueue.work if WorkerQueue::WorkerQueue.work?
  end

end
