#!/usr/bin/env ruby

require 'sinatra'
require 'haml'
require 'grit'
require 'rdiscount'

module GitWiki
  class << self
    attr_accessor :wiki_path, :root_page, :extension, :link_pattern
    attr_reader :wiki_name, :repository
    def wiki_path=(path)
      @wiki_name = File.basename(path)
      @repository = Grit::Repo.new(path)
    end
    def all_page_blobs
      @repository.tree.contents.select do |obj|
        obj.kind_of?(Grit::Blob) && obj.name.end_with?(@extension)
      end
    end
  end
end

class Page
  def self.find_all
    GitWiki.all_page_blobs.map {|blob| new(blob) }
  end

  def self.find_or_create(name, rev=nil)
    path = name + GitWiki.extension
    commit = rev ? GitWiki.repository.commit(rev) : GitWiki.repository.head.commit
    blob = commit.tree/path
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

  def name
    @blob.name.sub(/#{GitWiki.extension}$/, '')
  end

  def url
    name == GitWiki.root_page ? '/' : "/pages/#{name}"
  end

  def edit_url
    "/pages/#{name}/edit"
  end

  def log_url
    "/pages/#{name}/revisions/"
  end

  def css_class
    @blob.id ? 'existing' : 'new'
  end

  def content
    @blob.data
  end

  def to_html
    Page.wikify(RDiscount.new(content).to_html)
  end

  def log
    head = GitWiki.repository.head.name
    GitWiki.repository.log(head, @blob.name).map {|commit| commit.to_hash }
  end

  def save!(data, msg)
    msg = "web commit: #{name}" if msg.empty?
    Dir.chdir(GitWiki.repository.working_dir) do
      File.open(@blob.name, 'w') {|f| f.puts(data.gsub("\r\n", "\n")) }
      GitWiki.repository.add(@blob.name)
      GitWiki.repository.commit_index(msg)
    end
  end
end

set :haml, :format => :html5, :attr_wrapper => '"'

get '/' do
  @page = Page.find_or_create(GitWiki.root_page)
  haml :show
end

get '/pages/' do
  @pages = Page.find_all
  haml :list
end

get '/pages/:page/?' do
  @page = Page.find_or_create(params[:page])
  haml :show
end

get '/pages/:page/revisions/' do
  @page = Page.find_or_create(params[:page])
  haml :log
end

get '/pages/:page/revisions/:rev' do
  @page = Page.find_or_create(params[:page], params[:rev])
  haml :show
end

get '/pages/:page/edit' do
  @page = Page.find_or_create(params[:page])
  haml :edit
end

post '/pages/:page/edit' do
  @page = Page.find_or_create(params[:page])
  @page.save!(params[:content], params[:msg])
  redirect @page.url, 303
end

configure do
  GitWiki.wiki_path = Dir.pwd
  GitWiki.root_page = 'index'
  GitWiki.extension = '.md'
  GitWiki.link_pattern = /\[\[(.*?)\]\]/
end
