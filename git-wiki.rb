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

  def update_content(new_content)
    return if new_content == content
    File.open(file_name, "w") { |f| f << new_content }
    add_to_index_and_commit!
  end

  private
  def add_to_index_and_commit!
    Dir.chdir(GitWiki.repository.working_dir) {
      GitWiki.repository.add(@blob.name)
    }
    GitWiki.repository.commit_index("web commit: #{self}")
  end

  def file_name
    File.join(GitWiki.repository.working_dir, name + GitWiki.extension)
  end
end

set :haml, :format => :html5, :attr_wrapper => '"'
enable :inline_templates

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
  @page.update_content(params[:body])
  redirect "/#{@page}"
end

__END__
@@ layout
!!!
%html
  %head
    %title= title
  %body
    %ul
      %li
        %a{ :href => "/#{GitWiki.homepage}" } Home
      %li
        %a{ :href => "/pages" } All pages
    #content= yield

@@ show
- title @page.name
#edit
  %a{:href => "/#{@page}/edit"} Edit this page
%h1= title
#content
  ~"#{@page.to_html}"

@@ edit
- title "Editing #{@page.name}"
%h1= title
%form{:method => 'POST', :action => "/#{@page}"}
  %p
    %textarea{:name => 'body', :rows => 30, :style => "width: 100%"}= @page.content
  %p
    %input.submit{:type => :submit, :value => "Save as the newest version"}
    or
    %a.cancel{:href=>"/#{@page}"} cancel

@@ list
- title "Listing pages"
%h1 All pages
- if @pages.empty?
  %p No pages found.
- else
  %ul#list
    - @pages.each do |page|
      %li= list_item(page)
