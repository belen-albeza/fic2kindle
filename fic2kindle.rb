# encoding: UTF-8

require 'rubygems'
require 'tempfile'

require_relative 'leecher'

if ARGV.size != 3
  puts "ERROR. Use: ruby fic2kindle.rb STORY_ID START_CHAPTER END_CHAPTER"
  puts "Example: ruby fic2kindle.rb 4673929 1 3"
  exit
end

# Comment the following line and uncomment the next one to avoid the 30 seconds
# pause between GET requests.
# THIS VIOLATES FANFICTION.NET TERMS OF SERVICE, ONLY DO THIS WHEN YOU
# FETCH CONTENT FROM ANOTHER WEBSITE THAT ALLOWS IT.
leech = Leecher.new(ARGV[0], (ARGV[1].to_i)..(ARGV[2].to_i), true)
# leech = Leecher.new(ARGV[0], (ARGV[1].to_i)..(ARGV[2].to_i))


leech.run

