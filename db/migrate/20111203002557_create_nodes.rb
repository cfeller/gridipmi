class CreateNodes < ActiveRecord::Migration
  def self.up
    create_table :nodes do |t|
      t.string :hostname
      t.float :cur_temp
      t.string :temp_status
      t.float :thresh_unc
      t.float :thresh_ucr
      t.string :thresh_unr
      t.float :watermark_high
      t.float :watermark_low

      t.timestamps
    end
  end

  def self.down
    drop_table :nodes
  end
end
