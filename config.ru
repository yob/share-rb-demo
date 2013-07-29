require 'share'
require 'sinatra'

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
<script src="/js/share.uncompressed.js" type="text/javascript"></script>
<script src="/js/textarea.js" type="text/javascript"></script>
<script>
function init() {
  var socketUri = 'ws://' + document.location.host + '/socket';
  sharejs.open('test-document', 'text', socketUri, function(error, doc) {
    var elem = document.getElementById('pad');
    doc.attach_textarea(elem);
  });
}
</script>
</head><body onload='init();'>
<h1>share.rb demo</h1>
<textarea id='pad'></textarea>
</body></html>
EOF
    ]
  end
end

repository = Share::Repo.new

map '/socket' do
  run Share::WebSocketApp.new(repository)
end

map '/' do
  run ExampleApp.new
end
