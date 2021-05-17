require 'json'

Tvmaze = Class.new
class << Tvmaze
  include FeedBuilder

  def get_show_json(req)
    path_requested = req.path

    # extracting imdb ID from url path
    imdb_match = path_requested.match( %r{^/tvmaze/(tt[0-9]*)} )
    if imdb_match
      imdb_id = imdb_match[1]

      # defining location of cache file
      url_file   = "http://api.tvmaze.com/lookup/shows?imdb=#{imdb_id}"
    else
      id_match = path_requested.match( %r{^/tvmaze/([0-9]*)} )
      return unless id_match

      tvmaze_id = id_match[1]

      # defining location of cache file
      url_file   = "http://api.tvmaze.com/shows/#{tvmaze_id}"
    end

    # downloading the show's basic info in tvmaze
    download_file_with_cache(url_file)
  end

  def get_episodes(tvmaze_id)
    episodes = JSON.parse download_file_with_cache( "http://api.tvmaze.com/shows/#{tvmaze_id}/episodes?specials=1" )

    # converting timestamps (strings) into time objects
    episodes.each do |episode|
      stamp = episode['airstamp']
      episode['airstamp'] = if stamp
                                Time.parse stamp
                            else
                                Time.now + 24*60*60 # for nil airstamps put tomorrow as they air date
                            end
    end
    episodes.sort_by! {|e| e['airstamp']}

    # filtering by episodes already aired
    episodes.select! {|e| e['airstamp'] <= Time.now }
    episodes.reverse!
  end

  def get_feed(req)
    show_json = get_show_json req
    return unless show_json
    show_json = JSON.parse show_json

    tvmaze_id = show_json["id"]
    episodes = get_episodes tvmaze_id

    # filling feed fields
    show_content = {
      'title'    => "#{show_json['name']} episodes",
      'subtitle' => show_json['summary'],
      'id'       => show_json['updated'].to_s + episodes.first['id'].to_s,
      'link'     => show_json['url'],
      'updated'  => (episodes.first['airstamp'].iso8601 unless episodes.empty?),
      'author'   => 'tvmaze',
      'entries'  => episodes.take(50).collect do |episode|
        season = "S#{ episode['season'].to_s.rjust(2, '0') }"
        number = "E#{ episode['number'].to_s.rjust(2, '0') }" if episode['number']
        {
          'title'     => episode['name'],
          'link'      => episode['url'],
          'id'        => episode['url'],
          'published' => episode['airstamp'].iso8601,
          'updated'   => episode['airstamp'].iso8601,
          'author'    => 'tvmaze',
          'content'   => "#{season}#{number}<br/>#{episode['summary']}"
        }
        end
    }

    create_xml_feed show_content
  end
end
