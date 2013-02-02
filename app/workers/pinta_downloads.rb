class PintaDownloads
  @queue = :blog

  def self.perform()
    doc = Nokogiri::HTML(open("http://wordpress.org/extend/plugins/placeling/"))

    doc.css('meta').each do |meta|
      if meta['itemprop'] == "interactionCount"
        puts meta['content']
        content = meta['content']
        if content.split(":")[0] == "UserDownloads"
          val = content.split(":")[1].to_i
          puts val
          track! :plugin_download, val
          break
        end
      end
    end
  end
end