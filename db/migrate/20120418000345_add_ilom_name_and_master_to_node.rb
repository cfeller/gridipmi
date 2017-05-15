class AddIlomNameAndMasterToNode < ActiveRecord::Migration
  def self.up
    add_column :nodes, :ilom_name, :string
    add_column :nodes, :master, :boolean
  end

  def self.down
    remove_column :nodes, :master
    remove_column :nodes, :ilom_name
  end
end
