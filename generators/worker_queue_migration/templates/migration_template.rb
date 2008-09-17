class CreateWorkerQueueItems < ActiveRecord::Migration
  def self.up
    create_table :worker_queue_items, :options => 'ENGINE=InnoDB DEFAULT CHARSET=UTF8' do |t|
      t.column :task_name, :string
      t.column :task_group, :string
      t.column :class_name, :string
      t.column :method_name, :string
      t.column :argument_hash, :text
      t.column :data, :text
      t.column :start, :datetime
      t.column :status, :integer, :default => 0, :null => false
      t.column :skip_on_error, :boolean, :default => true, :null => false
      t.column :error_message, :string
      t.column :filename, :string
      t.column :lock_version, :integer, :default => 0, :null => false
      t.timestamps
    end
    
    change_column :worker_queue_items, :data, :text, :limit => 256.megabytes + 1
    add_index :worker_queue_items, :status
  end

  def self.down
    drop_table :worker_queue_items
  end
end
