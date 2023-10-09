class Blob < ApplicationRecord
    validates :id, uniqueness: true
end
