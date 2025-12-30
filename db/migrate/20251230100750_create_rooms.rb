class CreateRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :rooms do |t|
      t.string :title, null: false
      t.integer :price, null: false
      t.float :area
      t.text :address
      t.float :latitude, null: false
      t.float :longitude, null: false
      t.string :room_type
      t.string :status, default: 'available'
      t.text :description
      t.string :phone

      t.timestamps
    end

    # Add PostGIS geography column
    add_column :rooms, :location, :geography, limit: { srid: 4326, type: "point" }

    # Add indexes for performance
    add_index :rooms, :location, using: :gist
    add_index :rooms, :price
    add_index :rooms, :status
    add_index :rooms, :room_type
  end
end
