class AggregationController < ApplicationController

  def index


    respond_to do |format|
      format.html { render :layout => 'bootstrap' }
    end

  end

end
