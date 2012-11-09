require 'test_helper'

describe Forward::CLI do

  it 'parses a forwarded port' do
    forwarded = Forward::CLI.parse_forwarded('600')
    forwarded.has_key?(:port).must_equal true
    forwarded[:port].must_equal 600
  end

  it 'parses a forwarded host' do
    forwarded = Forward::CLI.parse_forwarded('mysite.dev')
    forwarded.has_key?(:host).must_equal true
    forwarded[:host].must_equal 'mysite.dev'
  end

  it 'parses a forwarded host and port' do
    forwarded = Forward::CLI.parse_forwarded('mysite.dev:88')
    forwarded.has_key?(:host).must_equal true
    forwarded.has_key?(:port).must_equal true
    forwarded[:host].must_equal 'mysite.dev'
    forwarded[:port].must_equal 88
  end

  it 'parses valid basic auth and returns username and password' do
    username = 'foo'
    password = 'bar'

    credentials = Forward::CLI.parse_basic_auth("#{username}:#{password}")
    credentials.first.must_equal username
    credentials.last.must_equal password
  end

  it 'validates basic auth and exits if invalid' do
    [ 'afadsfsdf', 'adsf:', ':bar' ].each do |credentials|
      lambda {
        dev_null { Forward::CLI.validate_basic_auth(credentials) }
      }.must_raise SystemExit
    end
  end

  it 'doesnt exit on valid ports' do
    Forward::CLI.validate_port(69).must_be_nil
    Forward::CLI.validate_port(3000).must_be_nil
    Forward::CLI.validate_port(65535).must_be_nil
  end

  it 'validates port and exits if invalid' do
    [ 0, 65536 ].each do |port|
      lambda {
        dev_null { Forward::CLI.validate_port(port) }
      }.must_raise SystemExit
    end
  end

  it 'doesnt exit on valid cnames' do
    [ 'foo.com', 'whatever-foo.com', 'www.foo.com', 'asdf.asdf.asdf.com' ].each do |cname|
      Forward::CLI.validate_cname(cname).must_be_nil
    end
  end

  it 'validates cname and exits if invalid' do
    [ 'whatever', 'asdfasdf.', '-asdf', 'adsf#$).com' ].each do |cname|
      lambda {
        dev_null { Forward::CLI.validate_cname(cname) }
      }.must_raise SystemExit
    end
  end

  it 'doesnt exit on valid subdomains' do
    [ 'foo', 'whatever-foo', 'asdf40' ].each do |subdomain|
      Forward::CLI.validate_subdomain(subdomain).must_be_nil
    end
  end

  it 'validates subdomain and exits if invalid' do
    [ '-asdf', 'adsf#$)' ].each do |subdomain|
      lambda {
        dev_null { Forward::CLI.validate_subdomain(subdomain) }
      }.must_raise SystemExit
    end
  end

end
