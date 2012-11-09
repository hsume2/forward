require 'test_helper'

describe Forward::Config do

  before :each do
    @config_attributes = {
      :api_token => 'abcdefg',
      :private_key => 'secret'
    }
    FileUtils.mkdir_p(ENV['HOME'])
  end

  after :each do
    FileUtils.rm(Forward::Config.config_path) if Forward::Config.present?
    FileUtils.rm(Forward::Config.key_path) if Forward::Config.key_file_present?
  end

  it "initializes a config with a hash" do
    config = Forward::Config.new(@config_attributes)

    @config_attributes.each do |key, value|
      config.send(key).must_equal value
    end
  end

  it "updates a config with a hash" do
    config = Forward::Config.new
    config.update(@config_attributes)

    @config_attributes.each do |key, value|
      config.send(key).must_equal value
    end
  end

  it "writes and reads a config from disk" do
    config = Forward::Config.new(@config_attributes)
    config.write

    saved_config = Forward::Config.load

    File.exist?(Forward::Config.config_path).must_equal true
    File.exist?(Forward::Config.key_path).must_equal true

    @config_attributes.each do |key, value|
      saved_config.send(key).must_equal value
    end
  end

  it "only writes config values to the config file" do
    config = Forward::Config.new(@config_attributes)
    config.write

    config_file = File.read(Forward::Config.config_path)
    config_file.include?('private_key').must_equal false
  end

  it "converts a config to a hash" do
    config = Forward::Config.new(@config_attributes)
    config_hash = config.to_hash

    @config_attributes.each do |key, value|
      config_hash[key].must_equal value
    end
  end

  it "raises exception with an empty config" do
    config = Forward::Config.new

    lambda { config.validate }.must_raise Forward::ConfigError
  end

  it "raises exception with an invalid config" do
    @config_attributes.delete(:api_token)
    config = Forward::Config.new(@config_attributes)

    lambda { config.validate }.must_raise Forward::ConfigError
  end

  # it "raises exception with bad config on write" do
  #   @config_attributes.delete(:private_key)
  #   config = Forward::Config.new(@config_attributes)
  # 
  #   lambda { config.write }.must_raise Forward::ConfigError
  # end

  it "raises exception when a config file is not found" do
    lambda { Forward::Config.load }.must_raise Forward::ConfigError
  end

  it "raises exception when a key file is not found" do
    File.open(Forward::Config.config_path, 'w') { |f| f.write YAML.dump(@config_attributes) }
    lambda { Forward::Config.load }.must_raise Forward::ConfigError
  end

end
