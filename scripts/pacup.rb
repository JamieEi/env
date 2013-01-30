#!/usr/bin/env ruby
require 'rss'
require 'time'

DEFAULT_LOG_FILE = '/var/log/pacman.log'
FEED_URL = 'http://www.archlinux.org/feeds/news/'
BUFFER_MINS = 60*24
@log = nil

def log_file
  if @log.nil?
    @log = DEFAULT_LOG_FILE
    File.open('/etc/pacman.conf', 'r') do |f|
      lf = f.readlines.select { |i| i !~ /^#/ and i =~ /LogFile/ }
      unless lf.empty?
        _log = lf[0].split(/=/)[1].strip
        @log = _log if File.exists? _log and File.readable? _log
      end
    end
  end
  @log
end

unless File.exists? log_file and File.readable? log_file
  raise "Unable to locate or read log file #{log_file}"
end

last_update = File.open(log_file, 'r') do |f|
  Time.parse f.readlines.select { |i| i =~ /starting full/ }.last
end

last_update = last_update - 60*BUFFER_MINS

feed = RSS::Parser.parse(FEED_URL)
items = feed.items.select { |i| i.pubDate >= last_update }
if items.count == 0
  puts "No news items since #{last_update}"
else
  items.each do |fi|
    puts <<EOI
#{fi.title.chomp} @ #{fi.pubDate}
#{fi.description}

EOI
  end
end