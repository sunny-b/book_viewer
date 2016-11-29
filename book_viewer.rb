require 'tilt/erubis'
require "sinatra"
require "sinatra/reloader" if development?


def filter_chapters(query)
  Dir.glob("data/*").select { |file| File.read(file).include? query }
end

def find_chapters(query)
  return [] unless query

  results = filter_chapters(query)
  results.map { |file| file.gsub(/[^0-9]/, '').to_i }.sort
end

def find_paragraphs(query, chapters)
  return [] unless query

  paragraphs = []
  indexes = []
  chapters.each do |chapter|
    next if chapter.zero?
    all_text = File.read("data/chp#{chapter}.txt").split("\n\n")
    paragraphs << all_text.select { |para| para.include? query }
    indexes << all_text.each_index.select { |i| all_text[i].include? query }
  end

  [paragraphs, indexes]
end

before do
  @toc = File.readlines 'data/toc.txt'
end

helpers do
  def in_paragraphs(text)
    text = text.split("\n\n")
    text.map.with_index { |para, idx| "<p id=\"#{idx + 1}\">#{para}</p>" }.join
  end

  def strong_paragraphs(text, query)
    text.gsub(query, "<strong>#{query}</strong>")
  end
end

get "/" do
  @title = "The Adventure of Sherlock Holmes"

  erb :home
end

get "/chapters/:number" do
  number = params[:number]
  @title = "Chapter #{number}: #{@toc[number.to_i - 1]}"
  @contents = File.read "data/chp#{number}.txt"

  erb :chapter
end

get '/search' do
  @query = params[:query]
  @found = find_chapters(@query)
  @paragraphs, @indexes = find_paragraphs(@query, @found)
  erb :search
end

not_found do
  redirect "/"
end
