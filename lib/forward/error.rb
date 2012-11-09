module Forward
	# An error occurred with the API
	class ApiError < StandardError; end
	# An error occurred with the Client
	class ClientError < StandardError; end
	# An error occurred with the Config
	class ConfigError < StandardError; end
	# An error occurred with the Tunnel
	class TunnelError < StandardError; end
end