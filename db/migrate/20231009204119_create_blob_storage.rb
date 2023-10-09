class CreateBlobStorage < ActiveRecord::Migration[7.0]
  def change
    create_table :blob_storage do |t|
      # t.uuid :blob_id, index: { unique: true }, foreign_key: true
      t.binary :data, null: false
      t.references :blob, foreign_key: true, type: :uuid
      t.timestamps
    end
  end
end
