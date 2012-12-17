module CarrierwaveCacheHelper
  extend ActiveSupport::Concern

  included do
    attr_accessor :cache_types
  end


  module ClassMethods

    def url_cache(*fields)

      cache_types = fields[0]


    end

  end


end