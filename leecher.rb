require 'net/http'
require 'erb'
require 'iconv'
require 'hpricot'

class Hash
  def to_binding
    res = Object.new
    res.instance_eval("def binding_for(#{keys.join(',')}) binding end")
    res.binding_for(*values)
  end
end

class String
  def to_utf8
    ::Iconv.conv('UTF-8//IGNORE', 'UTF-8', self + ' ')[0..-2]
  end
end

class Leecher
  FicSourceURL = "www.fanfiction.net"
  ChapterTemplate = 'chapter.html.erb'
  OpfTemplate = 'book.opf.erb'
  
  # constructor
  def initialize(fic_id, chapter_range)
    @fic_id = fic_id
    @chapter_range = chapter_range
    @chapters = []
    @opf = nil
  end
  
  def run
    puts $KCODE
    for i in @chapter_range do
      raw = leech_chapter(i)
      raw[:index] = 1
      
      file = Tempfile.new("chapter#{i}.html", ".")
      file << render_chapter(raw)
      @chapters.push(file.path)
    end
    
    @opf = render_opf({
      :chapters => @chapters,
      :title => "This is the fic title",
      :lang => "en",
      :author => "Anonymous",
      :publisher => "",
      :pub_date => Date.today.to_s,
      :description => ""
    })
    
    
    opf_file = File.new("book.opf", "w+")
    opf_file << @opf
    opf_file.close
    
    puts File.exist?(@chapters.first)
    
    
    puts `kindlegen book.opf -unicode`
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
      
      {:content => content.to_utf8, :title => title.to_utf8}
    end
  end
  
  # renders a chapter using a ERB template
  def render_chapter(data)
    template = ERB.new(File.read(ChapterTemplate))
    template.result(data.to_binding).to_utf8
  end
  
  # renders the OPF
  def render_opf(data)
    template = ERB.new(File.read(OpfTemplate))
    template.result(data.to_binding).to_utf8
  end
  
  def generate_ebook
    # dump the OPF template to a temp file
    opf_file = Tempfile.new
  end
end