require 'fileutils'
require 'rbconfig'
require 'yaml'

module Forward
  class Config
    CONFIG_FILE_VALUES = [ :api_token ]

    attr_accessor :id
    attr_accessor :api_token
    attr_accessor :private_key

    # Initializes a Config object with the given attributes.
    #
    # attributes - A Hash of attributes
    #
    # Returns the new Config object.
    def initialize(attributes = {})
      attributes.each do |key, value|
        self.send(:"#{key}=", value)
      end
    end

    # Updates an existing Config object.
    #
    # Returns the updated Config object.
    def update(attributes)
      Forward.log(:debug, 'Updating Config')
      attributes.each do |key, value|
        self.send(:"#{key}=", value)
      end

      self
    end

    # Converts a Config object to a Hash.
    #
    # Returns a Hash representation of the object
    def to_hash
      Hash[instance_variables.map { |var| [var[1..-1].to_sym, instance_variable_get(var)] }]
    end

    # Validate that the required values are in the Config.
    # Raises a config error if values are missing.
    def validate
      Forward.log(:debug, 'Validating Config')
      attributes = [:api_token, :private_key]
      errors = []

      attributes.each do |attribute|
        value = instance_variable_get("@#{attribute}")

        errors << attribute if value.nil? || value.to_s.empty?
      end

      if errors.length == 1
        raise ConfigError, "#{errors.first} is a required field"
      elsif errors.length >= 2
        raise ConfigError, "#{errors.join(', ')} are required fields"
      end
    end

    # Write the current config data to `config_path', and the current
    # private_key to `key_path'.
    #
    # Returns the Config object.
    def write
      Forward.log(:debug, 'Writing Config')
      key_folder  = File.dirname(Config.key_path)
      config_data = to_hash.delete_if { |k,v| !CONFIG_FILE_VALUES.include?(k) }

      self.validate

      FileUtils.mkdir(key_folder) unless File.exist?(key_folder)
      File.open(Config.config_path, 'w') { |f| f.write(YAML.dump(config_data)) }
      File.open(Config.key_path, 'w') { |f| f.write(private_key) }

      self
    rescue
      raise ConfigError, 'Unable to write config file'
    end

    # Shortcut for checking if host os is windows.
    #
    # Returns true or false if windows or not.
    def self.windows?
      RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
    end

    # Returns the location of the forward ssh private key
    # based on the host os.
    #
    # Returns the String path.
    def self.key_path
      if windows?
        File.join(ENV['HOME'], 'forward', 'key')
      else
        File.join(ENV['HOME'], '.ssh', 'forwardhq.com')
      end
    end

    # Returns the location of the forward config file
    # based on the host os.
    #
    # Returns the String path.
    def self.config_path
      if windows?
        File.join(ENV['HOME'], 'forward', 'config')
      else
        File.join(ENV['HOME'], '.forward')
      end
    end

    # Checks to see if a .forward config file exists.
    #
    # Returns true or false based on the existence of the config file.
    def self.present?
      File.exist? config_path
    end

    # Checks to see if a `private_key' exist.
    #
    # Returns true or false based on the existence of the key file.
    def self.key_file_present?
      File.exist? key_path
    end

    # Create a config file if it doesn't exist, load one if it does.
    #
    # Returns the resulting Config object.
    def self.create_or_load
      if Config.present?
        Config.load
      else
        Config.create
      end
    end

    # Create a config by authenticating the user via the api,
    # and saving the users api_token/id/private_key.
    #
    # Returns the new Config object.
    def self.create
      Forward.log(:debug, 'Creating Config')
      if @updating_config || ask('Already have an account with Forward? ').chomp =~ /\Ay/i
        config             = Config.new
        email, password    = CLI.authenticate.values_at(:email, :password)
        config.update(Forward::Api::User.api_token(email, password))
        Forward::Api.token = config.api_token
        config.private_key = Forward::Api::TunnelKey.create

        config.write
      else
        Client.cleanup_and_exit!("You'll need a Forward account first. You can create one at \033[04mhttps://forwardhq.com\033[0m")
      end
    end

    # It initializes a new Config instance, updates it with the config values
    # from the config file, and raises an error if there's not a config or if
    # the config options aren't valid.
    #
    # Returns the Config object.
    def self.load
      Forward.log(:debug, 'Loading Config')
      config = Config.new

      raise ConfigError, "Unable to find a forward config file at `#{config_path}'" unless Config.present?

      if File.read(config_path).include? '-----M-----'
        puts "Forward needs to update your config file, please re-authenticate"
        File.delete(config_path)
        @updating_config = true
        create_or_load
      end

      raise ConfigError, "Unable to find a forward key file at `#{key_path}'" unless Config.key_file_present?


      config.update(YAML.load_file(config_path).symbolize_keys)
      config.private_key = File.read(key_path)
      Forward::Api.token = config.api_token

      config.validate

      Forward.config = config

      config
    end

  end
end
