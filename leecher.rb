# encoding: UTF-8

require 'net/http'
require 'erb'
require 'iconv'
require 'open-uri'
require 'date'
require 'nokogiri'

class Hash
  def to_binding
    res = Object.new
    res.instance_eval("def binding_for(#{keys.join(',')}) binding end")
    res.binding_for(*values)
  end
end

class Leecher
  FicSourceURL = "http://www.fanfiction.net" 
  ChapterTemplate = 'chapter.html.erb'
  OpfTemplate = 'book.opf.erb'
  TocTemplate = 'toc.html.erb'
  
  # constructor
  def initialize(fic_id, chapter_range, legal_mode=false)
    @fic_id = fic_id
    @chapter_range = chapter_range
    @chapters = []
    @opf = nil
    @legal_mode = legal_mode
  end
  
  def run
    # get story info
    puts "Fetching http://www.fanfiction.net/s/#{@fic_id}"
    story_meta = leech_story_info
    
    # generate chapters
    @titles = []
    for i in @chapter_range do
      # a pause is needed to comply with FF.net TOS
      # plese read README file to more information about the TOS
      if @legal_mode
        puts "Making a 30 seconds pause to comply with fanfiction.net TOS..."
        puts "Read README file for more information about this issue"
        sleep 30
      end
      
      raw = leech_chapter(i)
      raw[:index] = i
      
      puts "Parsing chapter #{i}"
      create_html_file("chapter#{i}.html", ChapterTemplate, raw)
              
      @chapters.push("chapter#{i}.html")
      @titles.push(raw[:title])    
    end
    
    # generate TOC
    create_html_file("toc.html", TocTemplate, {
      :chapters => @chapters,
      :titles => @titles,
      :story_title => story_meta[:title],
      :story_author => story_meta[:author]
    })
    
    # generate OPF file
    create_html_file("book.opf", OpfTemplate, {
      :chapters => @chapters,
      :title => story_meta[:title],
      :lang => "en",
      :author => story_meta[:author],
      :toc => "toc.html"
    })
        
    puts "Generating ebook..."
    puts `kindlegen book.opf -unicode`
    
    cleanup
  end
  
  protected
  
  # creates a HTML file using the template and data provided
  def create_html_file(filename, template, data)
    File.open(filename, "w+:utf-8") do |file|
      file << ERB.new(File.read(template)).result(data.to_binding)
    end
  end
  
  # gets the book info from the front chapter in the story
  def leech_story_info
    doc = Nokogiri::HTML(open("#{FicSourceURL}/s/#{@fic_id}"), "UTF-8")    
    # get author name
    author = doc.xpath("//body/div[13]/table[1]//a").first.inner_text
    # get story title
    title = doc.xpath("//body/div[13]/div[1]//b").first.inner_text
    
    {:title => title, :author => author}
  end
  
  # downloads & process a single chapter
  def leech_chapter(index)
    # puts "Leeching chapter \##{index}..."
    doc = Nokogiri::HTML(open("#{FicSourceURL}/s/#{@fic_id}/#{index}"), "UTF-8")
    
    # get chapter content inside #storytext
    content = doc.xpath('//div[@id="storytext"]').first.inner_html
    # get chapter title from a dropdown menu
    # chapter titles in FF.net are written with this format: "28. This is a chapter"
    title = doc.xpath("//option[@value='#{index}']").first.inner_text.gsub(/^\d+\. /, "")
    
    {:content => content, :title => title}
  end
  
  # cleans up temporary files
  def cleanup
    filenames = ["book.opf", "toc.html"]
    filenames += @chapters
    
    filenames.each do |filename|
      File.delete(filename)
    end
  end
end