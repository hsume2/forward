module Forward
  module Api
    class ClientLog < Resource

      def self.create(log)
        resource     = ClientLog.new(:create)
        resource.uri = '/api/client_logs'
        params       = {
          :client => Forward.client_string,
          :log    => log
        }

        params[:api_token] = Forward.config.api_token unless Forward.config.nil?

        resource.post(params)
      end

    end
  end
end
