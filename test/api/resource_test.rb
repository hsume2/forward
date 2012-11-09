require 'test_helper'

describe Forward::Api::Resource do
  Api = Forward::Api

  before :each do
    Api.token = 'abc123'
  end

  it 'builds http requests based on given method' do
    resource     = Api::Resource.new
    resource.uri = '/path'

    [ :get, :post, :put, :delete ].each do |method|
      resource.build_request(method)
      klass   = eval("Net::HTTP::#{method.capitalize}")
      request = resource.instance_variable_get('@request')

      request.kind_of?(klass).must_equal true
    end
  end

  it 'builds http requests with json bodies' do
    resource     = Api::Resource.new
    resource.uri = '/path'

    [ :post, :put, :delete ].each do |method|
      params = { :foo => 'bar '}
      resource.build_request(method, params)
      klass   = eval("Net::HTTP::#{method.capitalize}")
      request = resource.instance_variable_get('@request')

      request.kind_of?(klass).must_equal true
      request.body.must_equal params.to_json
    end
  end

  it 'adds auth and json headers to the request' do
    resource     = Api::Resource.new
    resource.uri = '/path'
    resource.build_request(:post)
    resource.add_headers!
    request = resource.instance_variable_get('@request')

    request['Authorization'].must_equal "Token token=#{Api.token}"
    request['Content-Type'].must_equal 'application/json'
    request['Accept'].must_equal 'application/json'
  end


  it 'raises an error if the response code is not 200' do
    resource = Api::Resource.new
    response = mock
    response.stubs(:code).returns(403)
    response.stubs(:body)

    lambda { resource.parse_response(response) }.must_raise Api::BadResponse
  end

  it 'raises an error if the response is not json' do
    resource = Api::Resource.new
    response = mock
    response.stubs(:code).returns(200)
    response.stubs(:body)
    response.stubs(:[]).with('content-type').returns('text/html')

    lambda { resource.parse_response(response) }.must_raise Api::BadResponse
  end

  it 'parses a json response' do
    resource = Api::Resource.new
    response = mock
    response.stubs(:code).returns(200)
    response.stubs(:[]).with('content-type').returns('application/json')
    response.stubs(:body).returns('{ "foo": "bar" }')

    json = resource.parse_response(response)
    json.kind_of?(Hash).must_equal true
    json[:foo].must_equal 'bar'
  end

end
