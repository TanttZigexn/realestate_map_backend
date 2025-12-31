class CreateRoomViewings < ActiveRecord::Migration[8.0]
  def change
    create_table :room_viewings do |t|
      t.references :room, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone, null: false
      t.datetime :preferred_date, null: false
      t.text :message
      t.string :status, default: 'pending'

      t.timestamps
    end

    add_index :room_viewings, :email
    add_index :room_viewings, :status
    add_index :room_viewings, :preferred_date
  end
end

