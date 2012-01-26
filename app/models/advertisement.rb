class Advertisement

  attr_accessor :ad_type, :target_url, :image_url, :height, :width

  def initialize( ad_type )
    @ad_type = ad_type
    @target_url = "http://placeling.com/imack"
    @image_url = "http://www.mobistro.com/images/blog/GH.png"
    @height = 44
    @width = 320
  end

end