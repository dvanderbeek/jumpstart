class Account < ApplicationRecord
  belongs_to :owner, class_name: "User"

  validates :name, presence: true

  def email
    owner.email
  end

  def description
    "#{name}: #{owner.name}"
  end
end
