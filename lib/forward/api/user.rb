module Forward
  module Api
    class User < Resource

      def self.api_token(email, password)
        resource     = User.new(:api_token)
        resource.uri = '/api/users/api_token'
        params       = { :email => email, :password => password }

        resource.post(params)
      end

      def self.api_token_error(errors)
        Forward::Client.cleanup_and_exit!('Unable to authenticate with email and password')
      end

    end
  end
end
