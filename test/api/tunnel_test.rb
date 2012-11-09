require 'test_helper'

describe Forward::Api::Tunnel do

  before :each do
    FakeWeb.allow_net_connect = false
    Forward::Api.token      = 'abc123'
  end

  it 'creates a tunnel and returns the attributes' do
    Forward.client = mock
    fake_body      = { :_id => '1', :subdomain => 'foo', :port => 56789 }

    stub_api_request(:post, '/api/tunnels', :body => fake_body.to_json)

    response = Forward::Api::Tunnel.create(:port => 3000)

    fake_body.each do |key, value|
      response[key].must_equal fake_body[key]
    end
  end

  it 'exits with message if create response has errors' do
    Forward.client = mock
    fake_body      = { :errors => { :base => [ 'unable to create tunnel' ] } }

    stub_api_request(:post, '/api/tunnels', :body => fake_body.to_json)

    lambda { 
      dev_null { Forward::Api::Tunnel.create(:port => 3000) }
    }.must_raise SystemExit
  end

  it 'gives a choice and closes a tunnel if limit is reached' do
    Forward.client = mock
    post_options   = [
      { :body => { :errors => { :base => [ 'you have reached your limit' ] } }.to_json },
      { :body => { :_id => '1', :subdomain => 'foo', :port => 56789 }.to_json }
    ]
    index_body     = [ { :_id => 'abc123' }, { :_id => 'def456' } ]

    stub_api_request(:post, '/api/tunnels', post_options)
    stub_api_request(:get, '/api/tunnels', :body => index_body.to_json)
    STDIN.expects(:gets).returns('1')
    Forward::Api::Tunnel.expects(:destroy).with(index_body.first[:_id])

    dev_null { Forward::Api::Tunnel.create(:port => 3000) }
  end

  it 'destroys a tunnel and returns the attributes' do
    Forward.client = mock
    fake_body      = { :_id => '1', :subdomain => 'foo', :port => 56789 }

    stub_api_request(:delete, '/api/tunnels/1', :body => fake_body.to_json)

    response = Forward::Api::Tunnel.destroy(1)

    fake_body.each do |key, value|
      response[key].must_equal fake_body[key]
    end
  end

  it 'gracefully handles the error if destroy has errors' do
    Forward.client = mock
    fake_body      = { :errors => { :base => 'unable to create tunnel' } }

    stub_api_request(:delete, '/api/tunnels/1', :body => fake_body.to_json)

    Forward::Api::Tunnel.destroy(1).must_be_nil
  end

end
