module Forward
  class Tunnel
    CHECK_INTERVAL = 7

    # The Tunnel resource ID.
    attr_reader :id
    # The domain for the Tunnel.
    attr_reader :subdomain
    # The host
    attr_reader :host
    # The vhost
    attr_reader :vhost
    # The hostport (local port)
    attr_reader :hostport
    # The remote port.
    attr_reader :port
    # The tunneler host.
    attr_reader :tunneler
    # The amount of time in seconds the Tunnel has be inactive for
    attr_accessor :inactive_for

    # Initializes a Tunnel instance for the Client and requests a tunnel from
    # API.
    #
    # client - The Client instance.
    def initialize(options = {})
      @host         = options[:host]
      @response     = Forward::Api::Tunnel.create(options)
      @id           = @response[:_id]
      @subdomain    = @response[:subdomain]
      @vhost        = @response[:vhost]
      @hostport     = @response[:hostport]
      @port         = @response[:port]
      @tunneler     = @response[:tunneler_public]
      @timeout      = @response[:timeout]
      @inactive_for = 0
    end

    def poll_status
      Thread.new {
        loop do
          if @timeout && !@timeout.zero? && @inactive_for > @timeout
            Forward.log(:debug, "Session closing due to inactivity `#{@inactive_for}' seconds")
            Client.cleanup_and_exit!("Tunnel has been inactive for #{@inactive_for} seconds, exiting...")
          elsif Forward::Api::Tunnel.show(@id).nil?
            Client.current.tunnel = nil
            Forward.log(:debug, "Tunnel destroyed, closing session")
            Client.cleanup_and_exit!
          else
            sleep CHECK_INTERVAL
          end

          @inactive_for += CHECK_INTERVAL
        end
      }
    end

    def cleanup
      Forward::Api::Tunnel.destroy(@id) if @id
    end

    def active?
      @active
    end

  end
end
