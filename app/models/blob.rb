class Blob < ApplicationRecord
    validates :id, uniqueness: true
    
    has_one :blob_storage
end
