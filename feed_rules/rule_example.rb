RuleExample = Class.new
class << RuleExample
  include FeedBuilder

  def get_feed(req)
    example_feed = {
      'title'    => "A site title",
      'subtitle' => "Its subtitle",
      'id'       => "abcdefghijklmnopqrstuvwxyz",
      'link'     => "http://example.com",
      'updated'  => "2016-11-26T11:07:11",
      'author'   => 'John',
      'entries'  => [
        {
          'title'     => "entry's title",
          'link'      => "http://example.com/an_entry.htm",
          'id'        => 'a unique identifier',
          'published' => "2016-11-26T11:07:11",
          'updated'   => "2016-11-26T11:07:11",
          'author'    => 'John',
          'content'   => "some</br>html</br>you have entered the path: #{req.path}"
        }
      ]
    }

    create_xml_feed example_feed
  end
end
