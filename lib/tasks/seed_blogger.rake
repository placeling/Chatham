require 'pp'
require 'feedzirra'

namespace "blogger" do

  desc "Parse a remote feed looking for places that are blogged about"
  task :parse do

    Feedzirra::Parser::RSSEntry.elements "media:content", :as => :media_contents
    Feedzirra::Parser::RSS.element "generator"

    #Feedzirra::Feed.add_common_feed_entry_element('geo:lat', :as => :lat)

    feed = Feedzirra::Feed.fetch_and_parse("http://localhost/~imack/download.xml")

    puts feed.title
    puts feed.generator

    feed.entries.each do |entry|
      puts entry.url
      entry.media_contents.each do |media|
        PP.pp media
      end
    end
  end

end