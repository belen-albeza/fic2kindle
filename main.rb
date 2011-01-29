require 'rubygems'
require 'tempfile'

require 'leecher'

leech = Leecher.new("4338536", 1..1)
leech.run

# chapter_files = []
# leech.run.each_with_index do |chapter, index|
#   file = Tempfile.new("chapter#{index}.html", ".")
#   file << chapter
#   file.close
#   
#   chapter_files.push("chapter#{index}.html")
# end

