class Api::V1::UsersController < ApplicationController
  include ApiKeyAuthenticatable 

  # Require API key authentication                                             
  prepend_before_action :authenticate_with_api_key!, only: [:destroy]
  
  def create
    @user = User.create(user_params)

    if @user.save!
      "User created successfully"
    else
      @user.errors.full_messages
      render "User not created", status: :unprocessable_entity
    end
  end
  
  # def destroy
  #   puts current_bearer
  # end
  
  
  private

  def user_params
    params.require(:user).permit(:username, :password)
  end
  
end
