<%- # $Id: NgTzeYang [nineone@singnet.com.sg] 11 Sep 2008 17:51 $

start_contents, end_contents = [], []
indent = class_name.split('::').inject("") do | indent, name | 
  start_contents.push( indent + "class #{name}" )
  end_contents.unshift( indent + "end" )
  indent + "  "
end

start_contents[-1] += "Loader < WorkerQueue::WorkerQueueItemLoader"
start_contents << indent + %Q/
def self.prepare
  #
  # Example:
  # --
  # work.class_name     = 'SomeClass'
  # work.method_name    = 'some_method'
  # work.argument_hash  = { :some_arg => :some_val }
  # work.binary_data    = '1234567890'
  # work.skip_on_error  = false
  #
end 
/.strip.gsub( "\n", "\n#{indent}" )

-%>
<%= ( start_contents + end_contents ).join("\n") %>
