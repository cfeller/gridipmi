class AddUncExceededAndUcrExceededAndUncExceededCounterAndUcrExceededCounterToNode < ActiveRecord::Migration
  def self.up
    add_column :nodes, :unc_exceeded, :boolean
    add_column :nodes, :ucr_exceeded, :boolean
    add_column :nodes, :unc_exceeded_counter, :integer
    add_column :nodes, :ucr_exceeded_counter, :integer
  end

  def self.down
    remove_column :nodes, :ucr_exceeded_counter
    remove_column :nodes, :unc_exceeded_counter
    remove_column :nodes, :ucr_exceeded
    remove_column :nodes, :unc_exceeded
  end
end
