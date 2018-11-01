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

  has_many :services
  has_one :owned_account, class_name: "Account", inverse_of: :owner, foreign_key: :owner_id

  def account_name=(name)
    build_owned_account(name: name)
  end

  def account_name
    owned_account&.name
  end
end
