#!/bin/env ruby
# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'csv'
require 'scraperwiki'
require 'pry'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

@BASE = 'http://www.parliament.gov.sl/dnn5/AboutUs/MembersofParliament.aspx'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('table.telerik-reTable-1 td img').each do |img|
    cell = img.at_xpath('./following::td')
    rows = cell.text.split("\r\n").map { |t| t.gsub(/[[:space:]]+/, ' ').strip }.reject(&:empty?)
    data = {
      name: rows[0],
      image: img.attr('src'),
      term: '2-4',
    }
    data[:image] = URI.join(@BASE, URI.encode(URI.decode(data[:image])).gsub("[","%5B").gsub("]","%5D")).to_s unless data[:image].to_s.empty?
    if rows[1].include? 'Constituency'
      data[:area] = rows[2..3].join ", "
      data[:party] = rows[4]
    elsif rows[0].start_with? 'P.C'
      data[:area] = rows[1..2].join ", "
      data[:party] = 'Paramount Chief'
    else
      binding.pry
      raise "Problems with #{cell.text}"
    end
    # puts data
    ScraperWiki.save_sqlite([:name, :term], data)
  end
end

term = {
  id: '2-4',
  name: 'Fourth Parliament of the Second Republic',
  start_date: '2012',
  source: 'http://www.parliament.gov.sl/AboutUs/History.aspx',
}
ScraperWiki.save_sqlite([:id], term, 'terms')

# Weird ASP thing going on with browser detection so just cache the page
# for now
puts "*** scraping local file (within scraper repo), not remote website!"
scrape_list('MembersofParliament.aspx')
