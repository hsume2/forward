1. parse options
2. pass to client
3. client gets a session for the user based on stored token/authentication request or asks the user to signup
4. if account is in good standing client requests a tunnel to be setup
5. if tunnel is setup, client opens the ssh channel
6. client starts forwarding traffic
7. the end