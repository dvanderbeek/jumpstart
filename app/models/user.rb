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
  belongs_to :account

  def account_name=(name)
    build_owned_account(name: name)
    self.account = owned_account
  end

  def account_name
    account&.name
  end
end
