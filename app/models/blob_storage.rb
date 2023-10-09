class BlobStorage < ApplicationRecord
    self.table_name = "blob_storage"
    belongs_to :blob
end
