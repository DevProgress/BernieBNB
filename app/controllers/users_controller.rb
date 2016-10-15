class UsersController < ApplicationController
  before_action :ensure_current_user_is_user, only: [:edit, :show, :update, :destroy]
  skip_before_action :require_complete_profile, only: [:edit, :update, :confirm_email, :unsubscribe, :do_unsubscribe]
  skip_before_action :require_current_user, only: [:confirm_email, :unsubscribe, :do_unsubscribe]
  decorates_assigned :user

  def edit
  end

  def show
  end

  def unsubscribe
    @user = User.find_by_confirm_token(params[:id])

    if not @user
      flash[:errors] = ["Something went wrong, maybe you are already unsubscribed?  If you are having trouble please admin@hillarybnb.com"]
      redirect_to root_url
    end
  end

  def update
    if @user.update(user_params)
      if @user.email_confirmed
        redirect_to user_url(@user),
          notice: "Account updated"
      else
        UserMailer.registration_confirmation(@user).deliver_now
        sign_out!
        redirect_to root_url,
          notice: "Email confirmation sent, check your email for instructions"
      end

    else
      flash[:errors] = @user.errors.full_messages
      redirect_to edit_user_url(@user)
    end
  end

  def do_unsubscribe
    @user = User.find_by_confirm_token(params[:id])

    if @user
      if @user.destroy
        redirect_to root_url,
          notice: "OK, your account is deleted."
      else
        flash[:errors] = @user.errors.full_messages
        redirect_to root_url
      end
    else
      flash[:errors] = ["Something went wrong, maybe you are already unsubscribed?  If you are having trouble please admin@hillarybnb.com"]
      redirect_to root_url
    end
  end

  def destroy
    if @user.destroy
      redirect_to root_url,
        notice: "OK, your account is deleted."
    else
      flash[:errors] = @user.errors.full_messages
      redirect_to edit_user_url(@user)
    end
  end

  def confirm_email
    @user = User.find_by_confirm_token(params[:id])

    if @user
      @user.email_activate
      sign_in!(@user)

      UserMailer.welcome_email(@user)

      redirect_to user_url(@user)
    else
      flash[:errors] = ["Sorry, something went wrong.  Please try again, or email us at admin@hillarybnb.com for help."]
      redirect_to root_url
    end
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :phone, :email)
  end

  def ensure_current_user_is_user
    @user = User.find(params[:id])
    redirect_to user_url(current_user) unless @user == current_user
  end
end
