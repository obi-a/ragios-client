#specs for ragios-client
require 'ragios-client'


#communicating with server ->
#if no token get a token || current token is invalid
#get a new token
#apply this to couchdb admin on ragios, so that username and password is not sent  to server
#to get a token for every request
#improvement in terms of security, will deal with performance improvements when necessary

ragios = Ragios::Client.new

monitors = [{monitor: "my website",
		   every: "5m",
           url: "http://mywebsite.com",
           via: "twtter_notifier",
           plugin: "url_monitor" }]

ragios.login('admin', 'password')

ragios.add monitors

ragios.find(monitor_id)

ragios.all

ragios.stop(monitor_id)

ragios.restart(monitor_id)

ragios.delete(monitor_id)

ragios.find_by(options)

ragios.update(monitor_id, options)

ragios.test(monitor_id)

ragios.address = 'http://localhost'
ragios.port = '5041'

ragios.address
#=> http://localhost

ragios.port
#=> 5041
