require 'net/http'
require 'hpricot'

class Leecher
  FicSourceURL = "www.fanfiction.net"
  
  # constructor
  def initialize(fic_id, chapters)
    @fic_id = fic_id
    @chapters = chapters
  end
  
  def run
    for i in @chapters do
      leech_chapter(i)
    end
  end
  
  protected
  
  # downloads & process a single chapter
  def leech_chapter(index)
    puts "Leeching chapter \##{index}..."
    Net::HTTP.start(FicSourceURL) do |http|
      # get page and convert it to a Hpricot doc
      page = http.get("/s/#{@fic_id}/#{index}").body
      doc = Hpricot(page)
      
      # get chapter content inside #storytext
      content = doc.search('//div#storytext').first.html
      # get chapter title from a dropdown menu
      # chapter titles in FF.net are written with this format: "28. This is a chapter"
      title = doc.search("//option[@value='#{index}']").first.inner_text.gsub(/^\d+\. /, "")
    end
  end
    

end