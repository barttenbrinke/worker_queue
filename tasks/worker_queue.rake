require 'rake'
require 'rubygems'

namespace :worker_queue do

  desc 'Start the worker'
  task :work => :environment do
    WorkerQueue::WorkerQueue.work if WorkerQueue::WorkerQueue.work?
  end

end
