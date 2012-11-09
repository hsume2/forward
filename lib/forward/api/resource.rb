require 'cgi'
require 'json'
require 'net/http'
require 'net/https'
require 'uri'

module Forward
  module Api
    class Resource

      attr_accessor :http
      attr_accessor :uri

      def initialize(action = nil)
        @action           = action
        @http             = Net::HTTP.new(Forward::Api.uri.host, Forward::Api.uri.port)
        @http.use_ssl     = Forward::Api.ssl?
        @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        @http.ca_file     = File.expand_path('../../../../forwardhq.crt', __FILE__)
      end

      def request(method = :get, params = {})
        log(:debug, "Request: [#{method.to_s.upcase}] for `#{http.address}:#{http.port}#{uri}'")
        log(:debug, "Request: params `#{params.reject { |k,v| k == :password }.inspect }'")
        build_request(method, params)
        add_headers!

        response = @http.request(@request)

        parse_response(response)
      rescue ResourceError => e
        self.class.dispatch_error(e)
      end

      def build_request(method, params = {})
        @method = method

        case @method
        when :get
          @request = Net::HTTP::Get.new(uri)
        when :post
          @request = Net::HTTP::Post.new(uri)
          @request.body = params.to_json unless params.empty?
        when :put
          @request = Net::HTTP::Put.new(uri)
          @request.body = params.to_json unless params.empty?
        when :delete
          @request = Net::HTTP::Delete.new(uri)
          @request.body = params.to_json unless params.empty?
        end
      end

      def add_headers!
        if Forward::Api.token
          @request['Authorization'] = "Token token=#{Forward::Api.token}"
        end

        @request['Content-Type'] = 'application/json'
        @request['Accept']       = 'application/json'
      end

      def get(params = {})
        @response = request(:get, params)
      end

      def post(params = {})
        @response = request(:post, params)
      end

      def put(params = {})
        @response = request(:put, params)
      end

      def delete(params = {})
        @response = request(:delete, params)
      end

      def parse_response(response)
        log(:debug, "Response: [#{response.code}] `#{response.body}'")

        if response.code.to_i == 404
          raise ResourceNotFound
        elsif response.code.to_i != 200
          raise BadResponse, "response code was: #{response.code}"
        elsif response['content-type'] !~ /^application\/json/
          raise BadResponse, "response was not JSON, unable to parse"
        end

        json = JSON.parse(response.body)

        if json.is_a? Hash
          json.symbolize_keys!
          raise ResourceError.new(@action, json) if json.has_key?(:errors)
        end

        json
      end

      def self.dispatch_error(error)
        Forward.log(:debug, "Dispatching ResourceError:   action: #{error.action}   errors: #{error.errors.inspect}")
        method = :"#{error.action}_error"

        if respond_to? method
          send(method, error.errors)
        else
          Forward::Client.cleanup_and_exit!('An error occured, please contact support@forwardhq.com')
        end
      end

      private

      def log(level, message)
        unless self.class.to_s == 'Forward::Api::ClientLog'
          Forward.log(level, message)
        end
      end

    end

  end
end
