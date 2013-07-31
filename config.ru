require 'share'
require 'sinatra'
require 'browser_channel'

# a tiny sinatra app used for the demo
#
class ExampleApp < Sinatra::Base
  configure :production, :development do
    enable :logging
  end

  set :public_folder, File.dirname(__FILE__) + '/static'

  get "/" do
    [200, { 'Content-Type' => 'text/html' }, <<EOF
<html><head>
</head><body>
<h1>share.rb demo</h1>
<ul>
  <li><a href="/text">Text Document</a></li>
  <li><a href="/object">JSON Document</a></li>
</ul>
</body></html>
EOF
    ]
  end

  get "/text" do
    [200, { 'Content-Type' => 'text/html' }, <<EOF
<html><head>
<script src="/js/bcsocket-uncompressed.js" type="text/javascript"></script>
<script src="/js/share.uncompressed.js" type="text/javascript"></script>
<script src="/js/textarea.js" type="text/javascript"></script>
<script>
function init() {
  var wsUri = 'ws://' + document.location.host + '/socket';
  var bcUri = 'http://127.0.0.1:3000/channel';
  sharejs.open('test-document', 'text', bcUri, function(error, doc) {
    var elem = document.getElementById('pad');
    doc.attach_textarea(elem);
  });
}
</script>
</head><body onload='init();'>
<h1>share.rb text demo</h1>
<textarea id='pad' rows=10 cols=50></textarea>
</body></html>
EOF
    ]
  end

  get "/object" do
    [200, { 'Content-Type' => 'text/html' }, <<EOF
<html><head>
<script src="/js/bcsocket.js" type="text/javascript"></script>
<script src="/js/share.uncompressed.js" type="text/javascript"></script>
<script src="/js/json.uncompressed.js" type="text/javascript"></script>
<script src="/js/textarea.js" type="text/javascript"></script>
<script>
function init() {
  var socketUri = 'ws://' + document.location.host + '/socket';
  var options = {
    origin: socketUri,
    authentication: 123456
  }
  sharejs.open('json-document', 'json', options, function(error, doc) {
    if (!doc.snapshot) {
      doc.submitOp({p: [], od: null, oi: {title: '', body: ''}});
    }

    titleSubdocument = doc.at("title");
    var elem = document.getElementById('doctitle');
    titleSubdocument.attach_textarea(elem);

    bodySubdocument = doc.at("body");
    var elem = document.getElementById('docbody');
    bodySubdocument.attach_textarea(elem);
  });
}
</script>
</head><body onload='init();'>
<h1>share.rb JSON demo</h1>
<h2>Title</h2>
<textarea id='doctitle' rows=2 cols=50></textarea>
<h2>Body</h2>
<textarea id='docbody' rows=10 cols=50></textarea>
</body></html>
EOF
    ]
  end
end

class ShareBCHandler < BrowserChannel::Handler
  def call(post_data)
    puts "ShareBCHandler#call, post_data, #{post_data.inspect}"
    requests = decode_post_data(post_data)
    puts "  requests: #{requests.inspect}"
    #requests.each { |r| @session << [r] }
  end
  # called when channel session is final
  def terminate
  end
end

repository = Share::Repo.new

# option 1 for client connections - browserchannel
map '/channel' do
  run BrowserChannel::Server.new(:handler => ShareBCHandler)
end

# option 2 for client connections - websockets
map '/socket' do
  run Share::WebSocketApp.new(repository)
end

map '/' do
  run ExampleApp.new
end
