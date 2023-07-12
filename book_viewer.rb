require "tilt/erubis"
require "sinatra"
require "sinatra/reloader"

before do
  @contents = File.readlines("data/toc.txt")
end

not_found do
  redirect "/"
end

helpers do
  def in_paragraphs(text)
    text.split("\n\n").each_with_index.map do |line, index|
      "<p id=paragraph#{index}>#{line}</p>"
    end.join
  end

  def bold_results(text, query)
    text.gsub(query, %(<strong>#{query}</strong>))
  end
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  
  erb :home
end

get "/chapters/:number" do
  chapter_num = params[:number].to_i
  chapter_title = @contents[chapter_num - 1]

  redirect "/" if chapter_num > @contents.size
  
  @chapter = File.read("data/chp#{chapter_num}.txt")
  @title = "Chapter #{chapter_num}: #{chapter_title}"

  erb :chapter
end

def each_chapter
  @contents.each_with_index do |chap_name, idx|
    chap_number = idx + 1
    chap_text = File.read("data/chp#{chap_number}.txt")
    yield chap_number, chap_name, chap_text
  end
end

def chapter_match(query)
  results = []

  return results if !query || query.empty?

  each_chapter do |chap_num, chap_name, chap_text|
    matches = {}
    chap_text.split("\n\n").each_with_index do |paragraph, idx|
      matches[idx] = paragraph if paragraph.include?(query)
    end
    results << {number: chap_num, name: chap_name, paragraphs: matches} if matches.any?
  end
  results
end

get "/search" do
  @results = chapter_match(params[:query])

  erb :search
end