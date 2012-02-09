class AddNodeIdToLocation < ActiveRecord::Migration
  def self.up
    add_column :locations, :node_id, :integer
  end

  def self.down
    remove_column :locations, :node_id
  end
end
