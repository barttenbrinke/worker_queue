require 'rake'
require 'rubygems'

namespace :worker_queue do

  desc 'Load worker items'
  task :load => :environment do
    Dir.glob("#{RAILS_ROOT}/lib/worker_queue/**/*.rb").each do |file|
      require file
      class_name = file.sub(/^#{RAILS_ROOT}\/lib\/worker_queue\/(.*)\.rb$/,'\1').classify
      class_name.split('::').inject(Object) { | klass, const | klass.const_get(const) }.load
    end
  end

  desc 'Start the worker'
  task :work => :environment do
    WorkerQueue::WorkerQueue.work if WorkerQueue::WorkerQueue.work?
  end

end
