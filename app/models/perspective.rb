class Perspective
  include Mongoid::Document
  include Mongoid::Timestamps

  field :favorite,    :type => Boolean, :default => TRUE
  field :memo,        :type => String
  field :user_id,     :type => String #http://stackoverflow.com/questions/3890633/how-to-reference-an-embedded-document-in-mongoid

  #these are meant for internal use, not immediately visible to user -iMack
  field :location,    :type => Hash
  field :radius,      :type => Float

  embedded_in :place, :inverse_of => :perspectives
  index :user_id



end
