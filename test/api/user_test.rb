require 'test_helper'

describe Forward::Api::User do

  before :each do
    FakeWeb.allow_net_connect = false
  end

  it 'retrieves the users api token and returns it' do
    fake_body      = { :api_token => '123abc' }

    stub_api_request(:post, '/api/users/api_token', :body => fake_body.to_json)

    response = Api::User.api_token('guy@example.com', 'secret')
    response[:api_token].must_equal '123abc'
  end

  it 'exits with message if response has errors' do
    fake_body      = { :errors => { :base => 'Unable to authenticate user' } }

    stub_api_request(:post, '/api/users/api_token', :body => fake_body.to_json)

    lambda { 
      dev_null { Api::User.api_token('guy@example.com', 'secret') }
    }.must_raise SystemExit
  end

end
