require "spec_helper"
require 'json/ext'

describe "Workers - " do

  describe "perspective photos" do

    it "should be downloaded and attached to perspectives" do

      perspective = Factory.create(:perspective)
      GetPerspectivePicture.perform( perspective.id, ["http://www.placeling.com/images/blogFooterLogo.png"] )

      perspective.reload

      perspective.pictures.count.should == 1

    end

    it "should skipover images from urbanspoon (we get a 403)" do

      perspective = Factory.create(:perspective)
      GetPerspectivePicture.perform( perspective.id, ["http://www.urbanspoon.com/b/link/1543247/biglink.gif"] )

      perspective.reload

      perspective.pictures.count.should == 0

    end

  end

end