class AddIpmiAuthcapAndMbtAmbAndMbtAmbIdToNodes < ActiveRecord::Migration
  def self.up
    add_column :nodes, :ipmi_authcap, :string
    add_column :nodes, :mbt_amb, :string
    add_column :nodes, :mbt_amb_id, :Fixnum
  end

  def self.down
    remove_column :nodes, :mbt_amb_id
    remove_column :nodes, :mbt_amb
    remove_column :nodes, :ipmi_authcap
  end
end
