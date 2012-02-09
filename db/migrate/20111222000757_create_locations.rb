class CreateLocations < ActiveRecord::Migration
  def self.up
    create_table :locations do |t|
      t.integer :rack
      t.integer :rank
      t.string :hostname

      t.timestamps
    end
  end

  def self.down
    drop_table :locations
  end
end
