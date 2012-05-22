class ConfirmationsController < Devise::ConfirmationsController
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    
    if resource.errors.empty?
      sign_in(resource_name, resource)
      
      Resque.enqueue( WelcomeEmail, current_user.id)
      
      respond_to do |format|
        format.html
      end
    else
      respond_with_navigational(resource.errors, :status => :unprocessable_entity){ render :new }
    end
  end
end