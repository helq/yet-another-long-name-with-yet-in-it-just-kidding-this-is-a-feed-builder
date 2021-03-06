BecasYConvocatorias = Class.new
class << BecasYConvocatorias
  include FeedBuilder

  def get_feed(req)
    require 'open-uri'
    require 'nokogiri'

    url = 'http://becasyconvocatorias.org'
    page = Nokogiri::HTML open( url ).read

    articles = page.css('.article-container > article').collect.to_a
    (2..6).each do |page_num|
      one_more_page = Nokogiri::HTML open( "http://becasyconvocatorias.org/page/#{page_num}" ).read
      articles += one_more_page.css('.article-container > article').collect.to_a
    end

    example_feed = {
      'title'    => page.css('head > title').inner_text,
      'id'       => url,
      'link'     => url,
      'updated'  => parse_date( page.css('.article-container > article > .article-date').first.inner_text ).iso8601,
      'entries'  => articles.collect do |article|
        title         = article.css('.article-title > a').first.inner_text
        link          = article.css('.article-title > a').first.attributes['href'].value
        articles_date = parse_date( article.css('.article-date').inner_text ).iso8601
        content       = article.css('p').inner_html

        {
          'title'     => title,
          'link'      => link,
          'id'        => title,
          'published' => articles_date,
          'updated'   => articles_date,
          'content'   => content
        }
        end
    }

    create_xml_feed example_feed
  end

  def parse_date(str)
    matchDate = /^(\w+) (\d+), (\d+)$/.match str
    return Date.today unless matchDate

    day = matchDate[2]
    month = ['Enero', 'Febrero', 'Marzo', 'Abril',
             'Mayo', 'Junio', 'Julio', 'Agosto',
             'Septiembre', 'Octubre', 'Noviembre',
             'Diciembre'].index matchDate[1]
    year = matchDate[3]

    Date.parse "#{year}-#{month+1}-#{day}"
  end
end
