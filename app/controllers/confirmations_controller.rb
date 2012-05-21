class ConfirmationsController < Devise::ConfirmationsController
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    
    puts "Inside show"
    
    if resource.errors.empty?
      sign_in(resource_name, resource)
      
      puts "On line 10"
      
      respond_to do |format|
        format.html
      end
    else
      respond_with_navigational(resource.errors, :status => :unprocessable_entity){ render :new }
    end
  end
end