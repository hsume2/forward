module Forward
  class CLI
    CNAME_REGEX     = /\A[a-z0-9]+(?:[\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}\z/i
    SUBDOMAIN_REGEX = /\A[a-z0-9]{1}[a-z0-9\-]+\z/i
    BANNER = <<-BANNER
    Usage: forward <port> [options]
           forward <host> [options]
           forward <host:port> [options]

    Description:

       Share a server running on localhost:port over the web by tunneling
       through Forward. A URL is created for each tunnel.

    Simple example:

      # You are developing a Rails site.

      > rails server &
      > forward 3000
        Forward created at https://4ad3f-mycompany.fwd.wf

    Assigning a subdomain:

      > rails server &
      > forward 3000 myapp
        Forward created at https://myapp-mycompany.fwd.wf

    Virtual Host example:

      # You are already running something on port 80 that uses
      # virtual host names.

      > forward mysite.dev
        Forward created at https://dh43a-mycompany.fwd.wf

    BANNER

    # Parse non-published options and remove them from ARGV, then
    # parse published options and update the @options Hash with provided
    # options and removes switches from ARGV.
    def self.parse_options
      Forward.log(:debug, "Parsing options")
      @options = {
        :host   => '127.0.0.1',
        :port   => 80
      }

      if ARGV.include?('--debug')
        Forward.debug!
        ARGV.delete('--debug')
      elsif ARGV.include?('--debug-remotely')
        Forward.debug_remotely!
        ARGV.delete('--debug-remotely')
      end

      @opts = OptionParser.new do |opts|
        opts.banner = BANNER.gsub(/^ {6}/, '')

        opts.separator ''
        opts.separator 'Options:'

        opts.on('-a', '--auth [USER:PASS]', 'Protect this tunnel with HTTP Basic Auth.') do |credentials|
          username, password  = parse_basic_auth(credentials)
          @options[:username] = username
          @options[:password] = password
        end

        opts.on('-c', '--cname [CNAME]', 'Allow access to this tunnel as NAME.') do |cname|
          validate_cname(cname)
          @options[:cname] = cname
        end

        opts.on( '-h', '--help', 'Display this help.' ) do
          puts opts
          exit
        end

        opts.on('-v', '--version', 'Display version number.') do
          puts "forward #{VERSION}"
          exit
        end
      end

      @opts.parse!
    end

    # Attempts to validate the basic auth credentials, if successful updates
    # the @options Hash with given credentials.
    #
    # credentials - A String containing a username and password separated
    #               by a colon.
    #
    # Returns an Array containing the username and password
    def self.parse_basic_auth(credentials)
      validate_basic_auth(credentials)
      username, password  = credentials.split(':')

      [ username, password ]
    end

    # Parses the arguments to determine if we're forwarding a port or host
    # and validates the port or host and updates @options if valid.
    #
    # arg - A String representing the port or host.
    #
    # Returns a Hash containing the forwarded host or port
    def self.parse_forwarded(arg)
      Forward.log(:debug, "Forwarded: `#{arg}'")
      forwarded = {}

      if arg =~ /\A\d{1,5}\z/
        port = arg.to_i
        validate_port(port)

        forwarded[:port] = port
      elsif arg =~ /\A[-a-z0-9\.\-]+\z/i
        forwarded[:host] = arg
      elsif arg =~ /\A[-a-z0-9\.\-]+:\d{1,5}\z/i
        host, port = arg.split(':')
        port       = port.to_i
        validate_port(port)

        forwarded[:host] = host
        forwarded[:port] = port
      end

      forwarded
    end

    # Checks to make sure the port being set is a number between 1 and 65535
    # and exits with an error message if it's not.
    #
    # port - A String containing the port number.
    def self.validate_port(port)
      Forward.log(:debug, "Validating Port: `#{port}'")
      unless port.between?(1, 65535)
        exit_with_error "Invalid Port: #{port} is an invalid port number"
      end
    end

    # Checks to make sure the basic auth credentials are in the correct format
    # and exits with an error message if they're not.
    #
    # credentials - A String with the username and password for basic auth.
    def self.validate_basic_auth(credentials)
      Forward.log(:debug, "Validating Basic Auth: `#{credentials}'")
      if credentials !~ /\A[^\s:]+:[^\s:]+\z/
        exit_with_error "Basic Auth: bad format, expecting USER:PASS"
      end
    end

    # Checks to make sure the cname is in the correct format and exits with an
    # error message if it isn't.
    #
    # cname - A String containing the cname.
    def self.validate_cname(cname)
      Forward.log(:debug, "Validating CNAME: `#{cname}'")
      exit_with_error("`#{cname}' is an invalid domain format") unless cname =~ CNAME_REGEX
    end

    # Validates the subdomain and returns a Hash containing it.
    #
    # subdomain - A String containing the subdomain.
    #
    # Returns a Hash containing the subdomain
    def self.parse_subdomain(subdomain)
      validate_subdomain(subdomain)
      { :subdomain => subdomain }
    end

    # Checks to make sure the subdomain is in the correct format and exits with an
    # error message if it isn't.
    #
    # cname - A String containing the subdomain.
    def self.validate_subdomain(subdomain)
      Forward.log(:debug, "Validating Subdomain: `#{subdomain}'")
      exit_with_error("`#{subdomain}' is an invalid subdomain format") unless subdomain =~ SUBDOMAIN_REGEX
    end

    def self.validate_options
      Forward.log(:debug, "Validating options: `#{@options.inspect}'")
    end

    # Asks for the user's email and password and puts them in a Hash.
    #
    # Returns a Hash with the email and password.
    def self.authenticate
      puts 'Enter your email and password'
      email    = ask('email: ').chomp
      password = ask('password: ') { |q| q.echo = false }.chomp
      Forward.log(:debug, "Authenticating User: `#{email}:#{password.gsub(/./, 'x')}'")

      { :email => email, :password => password }
    end

    # Parses various options and arguments, validates everything to ensure 
    # we're safe to proceed, and finally passes @options to the Client.
    def self.run(args)
      Forward.log(:debug, "Starting forward v#{Forward::VERSION}")
      parse_options
      @options.merge!(parse_forwarded(args[0]))
      @options.merge!(parse_subdomain(args[1])) if args.length > 1
      validate_options

      print_usage_and_exit if args.empty?

      Client.start(@options)
    end

    # Colors an error message red and displays it.
    #
    # message - A String containing an error message.
    def self.exit_with_error(message)
      Forward.log(:fatal, message)
      puts "\033[31m#{message}\033[0m"
      exit 1
    end

    # Print the usage banner and Exit Code 0.
    def self.print_usage_and_exit
      puts @opts
      exit
    end

  end
end
