require 'pp'
require 'feedzirra'
require 'google_places_autocomplete'

class MediaEntry
  include SAXMachine

  attribute :url
  value :value
end


def getUrbanspoonPlaceCoordinates(urbanspoon_id)
  page = CrawledPage.find_by_qualified_id(urbanspoon_id)
  if page.nil?
    url = "http://www.urbanspoon.com/r/#{urbanspoon_id}"
    puts "Grabbing contents of #{url}"
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
        puts e
        next
      end

      if uri.host == "maps.google.com"
        query_params = CGI::parse(uri.query)
        puts image['src']

        if query_params['markers']
          rawMarker = query_params['markers'][0].split(",")
          return [rawMarker[0].to_f, rawMarker[1].to_f]
        end
      end
    end
  end

  return nil

end


namespace "blogger" do

  desc "Load a list of place urls and put them into blogger models"
  task :load, [:file_path] => :environment do |t, args|
    line_num=0
    filename = Rails.root + args.file_path
    puts "Slurping #{filename}"

    created_count = 0

    text=File.open(filename).read
    text.each_line do |line|
      line = line.strip
      if line[-1] != "/"
        line = line + "/"
      end

      puts "#{line_num += 1} #{line}"

      blogger = Blogger.find_by_url(line)

      if blogger.nil?
        Blogger.create!(:url => line)
        created_count += 1
      end
    end

    puts "Created #{created_count} bloggers"
  end


  desc "Parse a remote feed looking for places that are blogged about"
  task :parse => :environment do

    gpa = GooglePlacesAutocomplete.new
    Feedzirra::Parser::RSSEntry.elements "media:content", :as => :media_contents, :class => MediaEntry
    Feedzirra::Parser::RSS.element "generator"

    Blogger.where(:activated => false).and(:last_updated.lt => 1.day.ago).limit(100).each do |blogger|
      puts blogger.url
      feed = Feedzirra::Feed.fetch_and_parse(blogger.url + "feed/")

      if feed.nil? || feed.entries.nil? || feed.entries.first.nil? || feed.entries.first.published < 3.months.ago
        blogger.last_updated = DateTime.new
        blogger.save
        next
      end

      blogger.update_from_feedrizza(feed)

      feed.entries.each do |entry|

        next unless blogger.entries.where(:url => entry.url).count == 0
        puts "Looking at entry: #{entry.url}"

        nearby = nil
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
              puts place_name
              urbanspoon_id = uri.path.split("/")[3]

              if blogger.location.nil?
                loc = getUrbanspoonPlaceCoordinates(urbanspoon_id)
                blogger.location = loc
              end

              nearby = gpa.suggest(blogger.location[0], blogger.location[1], place_name)
              sleep 1

              urbanspoonCount += 1
            end
          end
        end
        if nearby && urbanspoonCount == 1
          blogger.entries.create(:url => entry.url, :title => entry.title, :description => entry.summary, :places => nearby, :slug => entry.entry_id)
        else
          blogger.entries.create(:url => entry.url, :title => entry.title, :description => entry.summary, :places => [], :slug => entry.entry_id)
        end
      end

      blogger.last_updated = 1.second.ago
      blogger.save

    end
  end

end