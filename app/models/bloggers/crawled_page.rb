class CrawledPage
  include Mongoid::Document
  include Mongoid::Timestamps

  field :qualified_id, :type => String
  field :url, :type => String
  field :html, :type => String

  index :qualified_id
  index :url

  def self.find_by_qualified_id(qid)
    self.where(:qualified_id => qid).first
  end

  def self.create_from_response(qid, url, response)
    self.create(:qualified_id => qid, :url => url, :html => response.body)
  end


end