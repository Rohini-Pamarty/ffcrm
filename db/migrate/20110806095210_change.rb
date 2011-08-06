class Change < ActiveRecord::Migration
  def self.up
      
      remove_column :projects, :uuid
      
    
  end

  def self.down
  end
end
