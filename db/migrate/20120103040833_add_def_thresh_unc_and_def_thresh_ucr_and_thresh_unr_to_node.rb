class AddDefThreshUncAndDefThreshUcrAndThreshUnrToNode < ActiveRecord::Migration
  def self.up
    add_column :nodes, :def_thresh_unc, :float
    add_column :nodes, :def_thresh_ucr, :float
    add_column :nodes, :def_thresh_unr, :string
  end

  def self.down
    remove_column :nodes, :def_thresh_unr
    remove_column :nodes, :def_thresh_ucr
    remove_column :nodes, :def_thresh_unc
  end
end
