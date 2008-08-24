class WorkerQueueMigrationGenerator < Rails::Generator::Base

  def manifest
    record do |m|
        m.migration_template 'migration_template.rb', 'db/migrate', :assigns => {
          :migration_name => "CreateWorkerQueueItems"
        }, :migration_file_name => "create_worker_queue_items"
    end
  end

end
