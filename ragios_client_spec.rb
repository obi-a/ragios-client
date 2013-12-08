#specs for ragios-client
require 'ragios-client'

ragios = Ragios::Client.new

monitors = [{monitor: "my website",
		   every: "5m",
           url: "http://mywebsite.com",
           via: "twtter_notifier",
           plugin: "url_monitor" }]

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
