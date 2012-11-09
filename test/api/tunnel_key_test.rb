require 'test_helper'

describe Forward::Api::TunnelKey do

  before :each do
    FakeWeb.allow_net_connect = false
  end

  it 'retrieves the public_key and returns it' do
    fake_body = { :private_key => 'ssh-key 1234567890' }

    stub_api_request(:post, '/api/tunnel_keys', :body => fake_body.to_json)

    response = Api::TunnelKey.create
    response.must_equal fake_body[:private_key]
  end

  it 'exits with message if response has errors' do
    fake_body = { :errors => { :base => 'Unable to retrieve a private key' } }

    stub_api_request(:post, '/api/tunnel_keys', :body => fake_body.to_json)

    lambda { 
      dev_null { Api::TunnelKey.create }
    }.must_raise SystemExit
  end

end
