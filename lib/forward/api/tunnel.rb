module Forward
  module Api
    class Tunnel < Resource

      def self.create(options = {})
        resource     = Tunnel.new(:create)
        resource.uri = '/api/tunnels'
        params       = {
          :hostport => options[:port],
          :vhost    => options[:host],
          :client   => Forward.client_string,
        }

        [ :subdomain, :cname, :username, :password ].each do |param|
          params[param] = options[param] unless options[param].nil?
        end

        resource.post(params)
      end

      def self.index
        resource     = Tunnel.new(:index)
        resource.uri = "/api/tunnels"

        resource.get
      end

      def self.destroy(id)
        resource     = Tunnel.new(:destroy)
        resource.uri = "/api/tunnels/#{id}"

        resource.delete
      end

      def self.show(id)
        resource     = Tunnel.new(:show)
        resource.uri = "/api/tunnels/#{id}"

        resource.get
      rescue Forward::Api::ResourceNotFound
        nil
      end

      private

      def self.ask_to_destroy(message)
        tunnels = index

        puts message
        choose do |menu|
          menu.prompt = "Choose a tunnel from the list to close or `q' to exit forward "

          tunnels.each do |tunnel|
            text = "tunnel forwarding port #{tunnel['hostport']}"
            menu.choice(text) { destroy_and_create(tunnel['_id']) }
          end
          menu.hidden('quit') { Forward::Client.cleanup_and_exit! }
          menu.hidden('exit') { Forward::Client.cleanup_and_exit! }
        end
      end

      def self.destroy_and_create(id)
        Forward.log(:debug, "Destroying tunnel: #{id}")
        destroy(id)
        puts "tunnel removed, now we're creating a new one"
        create(Forward.client.options)
      end

      def self.create_error(errors)
        Forward.log(:debug, "An error occured creating tunnel:\n#{errors.inspect}")
        base_errors = errors['base']

        if base_errors && base_errors.any? { |e| e.include? 'limit' }
          message = base_errors.select { |e| e.include? 'limit' }.first
          Forward.log(:debug, 'Tunnel limit reached')
          ask_to_destroy(message)
        else
          message = "We were unable to create your tunnel for the following reasons: \n"
          errors.each do |key, value|
            if key != 'base'
              message << " #{key} #{value.join(', ')}\n"
            elsif key == 'base' && value.include?('account')
              message << " #{value}\n"
            end
          end
          Forward::Client.cleanup_and_exit!(message)
        end
      end

      def self.destroy_error(errors)
        # TODO: this is where we will tie into the logger
        nil
      end

    end
  end
end
