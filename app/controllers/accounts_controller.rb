class AccountsController < ApplicationController
  before_action :authenticate_user!, :load_account

  def edit
  end

  def update
    if @account.update(permitted_params)
      redirect_to [:edit, @account], notice: "Your account was updated successfully."
    else
      render :new
    end
  end

  private

    def permitted_params
      params.fetch(:account, {}).permit(:name)
    end

    def load_account
      @account = current_user.account
    end
end