class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :masqueradable,
         :omniauthable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable

  has_person_name

  has_many :notifications, foreign_key: :recipient_id
  has_many :services
end
