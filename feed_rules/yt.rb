Yt = Class.new
class << Yt
  include FeedBuilder

  def rss_to_hash(yt_channel_rss)
    require 'nokogiri'

    page = Nokogiri::HTML yt_channel_rss

    {
      'title'     => page.title,
      'id'        => page.css('feed > id').children.first.content,
      'link'      => page.css('feed > link').first.attributes['href'].value,
      'updated'   => page.css('feed > entry > updated').children.first.content,
      'author'    => page.css('feed > author > name').children.first.content,
      'entries'   => page.css('feed > entry').collect do |entry|
        thumbnail   = entry.css('group > thumbnail').first.attributes
        thumb_url    = thumbnail['url'].value
        thumb_width  = thumbnail['width'].value.to_i / 2
        thumb_height = thumbnail['height'].value.to_i / 2
        img         = %{<img src="#{thumb_url}" style="width:#{thumb_width}px;height:#{thumb_height}px;">}
        description = '<div>' + entry.css('group > description').inner_text.gsub(/\n/, '</div><div>') + '</div>'
        {
          'title'     => entry.css('title').children.first.content,
          'link'      => entry.css('link').first.attributes['href'].value,
          'id'        => entry.css('id').inner_text,
          'published' => entry.css('published').inner_text,
          'updated'   => (Time.parse(entry.css('updated').inner_text) + 1).iso8601,
          'author'    => entry.css('author > name').inner_text,
          'content'   => %{<div style="display:inline-block;vertical-align:top;"> #{img} </div>
                           <div style="display:inline-block;"> #{description} </div>}
        }
      end
    }
  end

  def get_video_length(video_id)
    embeded_video_url  = "https://www.youtube.com/embed/#{video_id}"
    download_only_once = Time.parse '1970-01-01T00:00:00+00:00' # alternativelly  Time.at(0)

    extract_video_length = Proc.new do |embeded_video_content|
      length_seconds = embeded_video_content.match(/"length_seconds":([^,]*),/)[1].to_i
      hours,   length_seconds = length_seconds.divmod 3600
      minutes, seconds        = length_seconds.divmod 60

      if hours >= 1
        "[#{hours}:#{minutes.to_s.rjust(2,'0')}:#{seconds.to_s.rjust(2,'0')}]"
      else
        "[#{minutes}:#{seconds.to_s.rjust(2,'0')}]"
      end
    end

		download_file_with_cache( embeded_video_url,
                              cache_lifetime: download_only_once,
                              compression_func: extract_video_length
                            )
  end

  def get_feed(req)
    match_yt_channel_id = req.path.match( %r{^/yt/(U.|PL)([^/]*)} )
    return unless match_yt_channel_id
    if match_yt_channel_id[1] == 'PL'
        yt_channel_id = "PL#{match_yt_channel_id[2]}"
    else
        yt_channel_id = "UU#{match_yt_channel_id[2]}"
    end

    p yt_channel_id

    require 'open-uri'
    yt_channel_rss = open( "https://www.youtube.com/feeds/videos.xml?playlist_id=#{yt_channel_id}" ).read

    feed_content = rss_to_hash(yt_channel_rss)

    # adding videos length to each entry
    feed_content['entries'].each do |entry|
      video_id = entry['link'].match(/watch\?v=(.*)/)[1]
      entry['title'] = get_video_length(video_id) + ' ' + entry['title']
      entry['content'] = "#{entry['title']} | #{entry['author']} &lt;#{entry['link']}&gt;</br>" + entry['content']
    end

    create_xml_feed feed_content
  end
end
