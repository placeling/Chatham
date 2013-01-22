class PublisherCategory
  include Mongoid::Document
  include Mongoid::Slug

  field :name, :type => String
  field :description, :type => String, :default => ""

  field :module_type, :type => Integer, :default => 0

  field :creation_environment, :type => String
  field :main_cache_url, :type => String
  field :thumb_cache_url, :type => String
  field :file_size, :type => Integer

  field :list_liquid_template, :type => String, :default => File.read("#{::Rails.root.to_s}/config/templates/module_list.liquid")

  field :_type, type: String #makes an abstract class:  https://github.com/mongoid/mongoid/issues/2511

  mount_uploader :image, CategoryUploader

  embedded_in :publisher

  after_save :invalidate_cache

  slug :name, :permanent => true, :scope => :publisher

  liquid_methods :name, :slug, :description, :main_url, :thumb_url

  #url_cache [:main, :thumb]

  def image=(obj)
    super(obj)
    # Put your callbacks here, e.g.
    self.file_size = image.size
    self.creation_environment = nil
    self.main_cache_url = nil
    self.thumb_cache_url = nil
  end

  def invalidate_cache
    self.publisher.invalidate_cache
  end


  def cache_urls
    self.creation_environment = Rails.env
    self.main_cache_url = self.image_url
    self.thumb_cache_url = self.image_url(:thumb)
    self.save
  end

  def main_url
    if Rails.env == self.creation_environment
      self.image_url
    elsif main_cache_url
      main_cache_url
    else
      self.cache_urls
      self.image_url
    end
  end

  def thumb_url
    if Rails.env == self.creation_environment
      self.image_url(:thumb)
    elsif thumb_cache_url
      thumb_cache_url
    else
      self.cache_urls
      self.image_url(:thumb)
    end
  end

  def perspectives;
    raise "Abstract Method Called"
  end

  def as_json(options={})
    attributes = {:id => self['_id'],
                  :name => self.name,
                  :slug => self.slug,
                  :list_liquid_template => self.list_liquid_template,
                  :list_liquid_html => Liquid::Template.parse(self.list_liquid_template).render(nil)
    }

    attributes.merge(:image_url => self.main_url).merge(:thumb_url => self.thumb_url)
  end

end