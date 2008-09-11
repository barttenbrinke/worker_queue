# $Id: NgTzeYang [nineone@singnet.com.sg] 11 Sep 2008 17:48 $
#

class WorkerQueueItemLoaderGenerator < Rails::Generator::NamedBase

  def manifest
    record do |m|

      # Check for class naming collisions.
      m.class_collisions class_path, class_name, "#{class_name}Loader"

      m.directory File.join( 'lib/worker_queue', class_path )
      m.template 'loader.rb', File.join('lib/worker_queue', class_path, "#{file_name}_loader.rb")

    end
  end

end

# __END__
