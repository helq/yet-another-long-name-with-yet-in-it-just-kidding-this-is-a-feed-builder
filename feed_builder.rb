module FeedBuilder
  def set_cache_database
    return if @db # don't do anything if the db has been already setted
    cache_db = 'cache.db'

    require 'sqlite3'
    if not File.exists? cache_db
      @db = SQLite3::Database.new cache_db

      @db.execute <<-SQL
        create table files (
          url TEXT PRIMARY KEY,  -- url of the file
          mtime INT,             -- last modification time, meaning last time the file was dowloaded time
          last_access INT,       -- last time the file was queried
          data BLOB              -- compressed content
        );
      SQL
    else
      @db = SQLite3::Database.new cache_db
    end

    # cleaning old downloads from db
    a_month_ago = Time.now - (60 * 60 * 24 * 30)
    old_urls = @db.execute('select url from files where last_access < ?', [a_month_ago.to_i]).collect {|row| row[0]}
    @db.execute "delete from files where url in (#{ (['?'] * old_urls.size).join(',') })", old_urls if old_urls.size > 0

    @db.execute 'PRAGMA synchronous=OFF' # makes updates blastingly fast, it makes the database non acid
    #@db.execute 'PRAGMA journal_mode=OFF'
  end

  def download_file_with_cache(url, cache_lifetime: nil, compression_func: nil)
    #puts url

    require 'lz4-ruby'
    cache_db = 'cache.db' unless cache_db
    cache_lifetime = Time.now - (60 * 60 * 24) unless cache_lifetime # 24 hours ago

    set_cache_database

    query_result = @db.execute 'select * from files where url = ?', url
    if query_result.size > 0
      cached_file = { url:         query_result[0][0],
                      mtime:       query_result[0][1],
                      last_access: query_result[0][2],
                      data:        query_result[0][3]
                    }
      @db.execute 'update files set last_access = ? where url = ?', [Time.now.to_i, url]
    end

    # download file if cache lifetime expired or if there is no such file in the cache
    if query_result.size == 0 or cache_lifetime > Time.at( cached_file[:mtime] )
      require 'open-uri'

      #p url
      downloaded_file = URI.open( url ).read
      if not compression_func.nil?
        downloaded_file = compression_func.call downloaded_file
      end
      compressed_file = LZ4::compressHC downloaded_file

      if query_result.size == 0
        @db.execute 'insert into files (url, mtime, last_access, data) values ( ?, ?, ?, ? )', [url, Time.now.to_i, Time.now.to_i, compressed_file]
      else
        @db.execute 'update files set (mtime, last_access, data) = ( ?, ?, ? ) where url = ?', [Time.now.to_i, Time.now.to_i, compressed_file, url]
      end

      return downloaded_file
    else
      return LZ4::uncompress( cached_file[:data] )
    end
  end

  def create_xml_feed(feed_content)
    # expected structure for feed_content
    # {
    #   'title'    => 'Web pages name',
    #   'subtitle' => 'their subtitle', # optional
    #   'id'       => ...,
    #   'link'     => ...,
    #   'updated'  => '2012-03-22T12:00:00+00:00', # optional
    #   'author'   => ...,
    #   'content'  => [
    #     {
    #       'title'     => 'Last entry',
    #       'link'      => ...,
    #       'id'        => ...,
    #       'published' => ...,
    #       'updated'   => ...,
    #       'author'    => ...,
    #       'content'   => 'some html formated <\br> content'
    #     },
    #     {
    #       'title'     => 'One entry before last',
    #       'link'      => ...,
    #       'id'        => ...,
    #       'published' => ...,
    #       'updated'   => ...,
    #       'author'    => ...,
    #       'content'   => 'some html formated <\br> content'
    #     }
    #   ]
    # }
    #require 'pp'
    #return PP.pp feed_content['episodes'], '', 150

    xml = Builder::XmlMarkup.new( :indent => 2 )
    xml.instruct!

    xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do
      xml.title      feed_content['title']
      xml.subtitle(  feed_content['subtitle'], "type" => "html") if feed_content['subtitle']
      xml.id         feed_content['id']
      xml.link       "href" => feed_content['link']
      xml.updated(   feed_content['updated'] ) if feed_content['updated']
      xml.author { xml.name feed_content['author'] }

      feed_content['entries'].each do |entry|
        xml.entry do
          xml.title      entry['title']
          xml.link       "rel" => "alternate", "href" => entry['link']
          xml.id         entry['id']
          xml.published  entry['published']
          xml.updated    entry['updated'] if entry['updated']
          xml.author     { xml.name entry['author'] }
          xml.content    entry['content'], "type" => "html"
        end
      end
    end
  end
end
