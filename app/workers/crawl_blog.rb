require 'pp'
require 'feedzirra'
require 'google_places_autocomplete'

class MediaEntry
  include SAXMachine

  attribute :url
  value :value
end


def findRssFeed(blogger)

  response = Net::HTTP.get_response(URI.parse(blogger.url))

  if response.code == "200"
    doc = Nokogiri::HTML(response.body)
    alternates = []

    doc.css('link').each do |link|
      if link['rel'] == "alternate"
        begin
          uri = URI.parse(link['href'])
        rescue Exception => e
          next
        end

        if !link['title'].include?("Comments Feed")
          alternates << link
        end
      end
    end

    if alternates.count > 0
      RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - Adding feed url of #{alternates[0]['href']}"
      blogger.feed_url = alternates[0]['href']
      blogger.save
      Resque.enqueue(CrawlBlog, blogger.id) #put back in for crawling
    end
  end
end


def grabUrbanspoonId(summary)
  doc = Nokogiri::HTML(summary)

  urbanspoon_count = 0
  urban_id =nil
  place_name = nil

  doc.css('img').each do |image|
    begin
      uri = URI.parse(image['src'])
    rescue Exception => e
      next
    end

    if uri.host == "www.urbanspoon.com"
      urbanspoon_count += 1
      urban_id = uri.path.split("/")[3]
      place_name = image['alt'].gsub(" on Urbanspoon", "").strip
    end
  end

  if urbanspoon_count == 1
    return urban_id, place_name
  else
    return nil, nil
  end

end


def getUrbanspoonPlaceCoordinates(urbanspoon_id)
  page = CrawledPage.find_by_qualified_id(urbanspoon_id)
  if page.nil?
    url = "http://www.urbanspoon.com/r/#{urbanspoon_id}"
    RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - Scraping contents of #{url}"

    #@http.initialize_http_header({'User-Agent' => "Mozilla/5.0 (compatible; wp-blogger-trackback-bot)" })
    response = Net::HTTP.get_response(URI.parse(url))

    i=0
    while response.code == "301" || response.code == "302"
      i+=1
      return if i > 4
      response = Net::HTTP.get_response(URI.parse(response.header['location']))
    end

    if response.code == "200"
      page = CrawledPage.create_from_response(urbanspoon_id, url, response)
    else
      page = nil
    end

    sleep 2
  end

  if page
    doc = Nokogiri::HTML(page.html)

    doc.css('img').each do |image|
      begin
        uri = URI.parse(image['src'])
      rescue Exception => e
        next
      end

      if uri.host == "maps.google.com"
        query_params = CGI::parse(uri.query)

        if query_params['markers']
          rawMarker = query_params['markers'][0].split(",")
          return [rawMarker[0].to_f, rawMarker[1].to_f]
        end
      end
    end
  end

  return nil

end


class CrawlBlog
  @queue = :blog

  def self.perform(blogger_id)

    blogger = Blogger.find(blogger_id)
    RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - Crawling Blog #{blogger.url}"


    gpa = GooglePlacesAutocomplete.new

    Feedzirra::Parser::RSSEntry.elements "media:content", :as => :media_contents, :class => MediaEntry
    Feedzirra::Parser::RSS.element "generator"

    if blogger.feed_url.nil?
      check_url = blogger.url + "feed/"
    else
      check_url = blogger.feed_url
    end

    feed = Feedzirra::Feed.fetch_and_parse(check_url, {:max_redirects => 3, :timeout => 10})

    if feed.nil? && blogger.feed_url.nil?
      findRssFeed(blogger)
      return
    elsif feed.nil?
      blogger.last_updated = 1.second.ago
      blogger.save
      return
    elsif !defined?(feed.entries) || feed.entries.nil? || feed.entries.first.nil?
      blogger.last_updated = 1.second.ago
      blogger.save
      return
    elsif feed.entries.first.published < 3.months.ago
      blogger.auto_crawl = false
      blogger.save
      return
    end

    blogger.update_from_feedrizza(feed)

    return unless blogger.wordpress

    blogger.feed_url = check_url

    feed.entries.each do |entry|

      next unless blogger.entries.where(:url => entry.url).count == 0
      RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - Looking at entry: #{entry.url}"

      nearby = nil
      urbanspoon_id = nil


      if defined? entry.media_contents #might not exist for atom
        urbanspoonCount = 0
        entry.media_contents.each do |media|
          if media.url
            begin
              uri = URI.parse(media.url)
            rescue Exception => e
              next
            end

            if uri.host == "www.urbanspoon.com"
              place_name = media.value.gsub(" on Urbanspoon", "").strip
              RESQUE_LOGGER.info "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - Parsing place: #{place_name}"
              urbanspoonCount += 1
            end

            if urbanspoonCount == 1
              urbanspoon_id = uri.path.split("/")[3]
            end
          end
        end
      end

      if urbanspoon_id.nil?
        urbanspoon_id, place_name = grabUrbanspoonId(entry.content)
      end

      if blogger.location.nil? && urbanspoon_id
        loc = getUrbanspoonPlaceCoordinates(urbanspoon_id)
        sleep 1
        blogger.location = loc
      end

      if blogger.location && place_name
        nearby = gpa.suggest(blogger.location[0], blogger.location[1], place_name)

        if nearby
          blogger.entries.create(:url => entry.url, :title => entry.title, :content => entry.content, :places => nearby, :slug => entry.entry_id)
        else
          blogger.entries.create(:url => entry.url, :title => entry.title, :content => entry.content, :places => [], :slug => entry.entry_id)
        end
      end

    end

    blogger.last_updated = 1.second.ago
    blogger.save
  end
end