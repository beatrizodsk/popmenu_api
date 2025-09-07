class MenuItem < ApplicationRecord
  belongs_to :menu

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
end
