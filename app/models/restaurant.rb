class Restaurant < ApplicationRecord
  has_many :menus, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
