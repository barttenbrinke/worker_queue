require 'rake'
require 'rubygems'

namespace :worker_queue do

  desc 'Load worker items'
  task :load => :environment do
    Dir.glob("#{RAILS_ROOT}/lib/worker_queue/*.rb").each do |file|
      require file
      Object.const_get(File.basename(file,'.rb').classify).load
    end
  end

  desc 'Start the worker'
  task :work => :environment do
    WorkerQueue::WorkerQueue.work if WorkerQueue::WorkerQueue.work?
  end

end
