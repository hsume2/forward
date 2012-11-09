require 'forward/api/resource'
require 'forward/api/client_log'
require 'forward/api/tunnel_key'
require 'forward/api/tunnel'
require 'forward/api/user'

module Forward
  module Api
    class BadResponse < StandardError; end
    class ResourceNotFound < StandardError; end
    class ResourceError < StandardError
      attr_reader :action, :errors

      def initialize(action, json)
        @action = action
        @json   = json
        @errors = json[:errors]
      end
    end

    DEFAULT_API_HOST = 'https://forwardhq.com'

    # Returns either an api host set in the environment or a set default.
    #
    # Returns a String containing the api host.
    def self.uri
      URI.parse(ENV['FORWARD_API_HOST'] || DEFAULT_API_HOST)
    end

    # Returns True or False if we should be using ssl
    #
    # Returns a Boolean.
    def self.ssl?
      uri.scheme == 'https'
    end

    def self.token=(token)
      @@api_token = token
    end

    def self.token
      defined?(@@api_token) ? @@api_token : nil
    end
  end
end
