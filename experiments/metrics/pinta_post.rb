metric "Pinta" do
  description "Posts created with the Wordpress Plugin"

  def values(from, to)
    vals = []
    (from..to).map do |i|
      vals << Perspective.where(:created_at.gte => i, :created_at.lte => i.next_day, :client_application_id => "4f298a1057b4e33324000003").count
    end

    return vals
  end
end