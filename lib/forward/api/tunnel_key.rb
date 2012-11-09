module Forward
  module Api
    class TunnelKey < Resource

      def self.create
        resource     = TunnelKey.new(:create)
        resource.uri = '/api/tunnel_keys'

        response = resource.post

        response[:private_key]
      end

    end
  end
end
