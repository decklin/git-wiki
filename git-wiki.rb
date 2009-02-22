#!/usr/bin/env ruby

require 'sinatra'
require 'haml'
require 'grit'
require 'rdiscount'

module GitWiki
  class << self
    attr_accessor :homepage, :extension, :repository, :link_pattern
  end
  @repository = Grit::Repo.new(ARGV[0] || File.expand_path('~/wiki'))
  @extension = ARGV[1] || '.markdown'
  @homepage = ARGV[2] || 'Home'
  @link_pattern = /\[\[(.*?)\]\]/
end

class Page
  def self.find_all
    GitWiki.repository.tree.contents.collect {|blob| new(blob) }
  end

  def self.find_or_create(name)
    path = name + GitWiki.extension
    blob = GitWiki.repository.tree/path
    new(blob || Grit::Blob.create(GitWiki.repository, :name => path))
  end

  def self.wikify(content)
    content.gsub(GitWiki.link_pattern) {|match| link($1) }
  end

  def self.link(text)
    page = find_or_create(text.gsub(/[^\w\s]/, '').split.join('-').downcase)
    "<a class='page #{page.css_class}' href='#{page.url}'>#{text}</a>"
  end

  def initialize(blob)
    @blob = blob
  end

  def to_html
    Page.wikify(RDiscount.new(content).to_html)
  end

  def to_s
    name
  end

  def css_class
    @blob.id ? 'existing' : 'new'
  end

  def name
    @blob.name.gsub(/#{File.extname(@blob.name)}$/, '')
  end

  def content
    @blob.data
  end

  def save!(data)
    Dir.chdir(GitWiki.repository.working_dir) do
      File.open(@blob.name, 'w') {|f| f.puts(data.gsub("\r\n", "\n")) }
      GitWiki.repository.add(@blob.name)
      GitWiki.repository.commit_index("web commit: #{self}")
    end
  end
end

set :haml, :format => :html5, :attr_wrapper => '"'

get "/" do
  redirect "/" + GitWiki.homepage
end

get "/pages" do
  @pages = Page.find_all
  haml :list
end

get "/:page/edit" do
  @page = Page.find_or_create(params[:page])
  haml :edit
end

get "/:page" do
  @page = Page.find_or_create(params[:page])
  haml :show
end

post "/:page" do
  @page = Page.find_or_create(params[:page])
  @page.save!(params[:body])
  redirect "/#{@page}"
end
