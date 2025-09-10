class MenuItem < ApplicationRecord
  has_and_belongs_to_many :menus

  validates :name, presence: true, uniqueness: true
  validates :price, presence: true, numericality: { greater_than: 0 }
end
