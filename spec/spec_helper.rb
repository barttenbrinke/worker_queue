require "rubygems"

ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")
require 'spec'
require 'spec/rails'

require File.expand_path(File.dirname(__FILE__) + "/../lib/worker_queue/worker_queue")
