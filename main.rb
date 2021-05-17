require 'builder'
require 'rack'

load 'feed_builder.rb'

# loading all feed rules
Dir.glob('feed_rules/*') do |fname|
  load fname
end

def _404(message)
  [404, {'Content-Type' => 'text/plain'}, [message]]
end

app = lambda do |env|
  request = Rack::Request.new(env) # request documentation: http://www.rubydoc.info/gems/rack/Rack/Request

  # extracting name of rule from path
  feed_rule_name = request.path.match( %r{^/([^/]*)} )
  return _404("write a valid path\nexample: #{request.base_url}/tvmaze/tt1305826") unless feed_rule_name

  # getting class from the rule name
  rule = Kernel.const_get feed_rule_name[1].split('_').collect(&:capitalize).join

  # creating feed with given info
  #p rule
  feed = rule::get_feed request
  if feed
    [200, {'Content-Type' => 'application/xml'}, [feed]]
  else
    _404 "Bad url or rule isn't working. TODO: improve error reporting, sorry ;)"
  end
end

Rack::Handler::WEBrick.run app, :Port => 53412
