self_file =
  if File.symlink?(__FILE__)
    require 'pathname'
    Pathname.new(__FILE__).realpath
  else
    __FILE__
  end

$:.unshift(File.dirname(self_file) + "/../")

require 'rubygems'
require 'model/init'

group = Group.find_or_create(:name => 'scraper')

feeds = ARGV.map{|u|
  puts "fetching feed: #{u.strip}"
  Feed.find_feeds(u.strip)
}.flatten.compact
feeds.each do |feed|
  begin
    group.add_feed(feed)
  rescue => e
    p e
  else
    p [group, feed]
    Activity.subscribe(group, feed)
  end
end
puts "done"
puts "group: " + group.name
puts group.feeds.map(&:uri)
