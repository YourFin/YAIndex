class Request < ApplicationRecord
  validates :body, presence: true
end
