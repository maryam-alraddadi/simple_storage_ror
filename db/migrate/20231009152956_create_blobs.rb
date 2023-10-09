class CreateBlobs < ActiveRecord::Migration[7.0]
  def change
    create_table :blobs, id: false do |t|
      t.uuid :id
      t.string :data
      t.string :size

      t.timestamps
    end
    execute "ALTER TABLE blobs ADD PRIMARY KEY (id);"
  end
end
