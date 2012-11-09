$LOAD_PATH.unshift(File.expand_path('../../spec', __FILE__))

require 'rubygems'
require 'yaml'
require 'bundler'
Bundler.setup

require 'minitest/autorun'
require 'minitest/pride'
require 'fakefs'
require 'fakeweb'
require 'forward'
require 'mocha'

ENV['FORWARD_API_HOST'] = 'http://localhost:3000'

def dev_null(&block)
  begin
    orig_stdout = $stdout.dup
    $stdout.reopen('/dev/null', 'w')
    yield
  ensure
    $stdout.reopen(orig_stdout)
  end
end

def stub_api_request(action = :get, path = '/', options = {})
  uri     = "#{Forward::Api.uri.host}:#{Forward::Api.uri.port}#{path}"
  base_options = {
    :status        => [ 200, 'OK' ],
    'content-type' => 'application/json'
  }

  if options.is_a?(Array)
    options.map! { |o| base_options.merge(o) }
  else
    options = base_options.merge(options)
  end

  FakeWeb.register_uri(action, uri, options)
end
