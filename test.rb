require 'rubygems'
require 'bundler/setup'

require 'amqp'
require 'json'

AMQP.start(:vhost => '/graylog') do |connection|
  AMQP::Channel.new( connection ) do |channel|

    # Setup a direct exchange
    channel.direct("logging") do |exchange|
      # Setup our queue and bind it
      channel.queue( 'graylog', :durable => true ).bind( exchange, :routing_key => 'graylog.gelf' )

      EM.add_periodic_timer(1) {
        data = {
          :host => "partyhat",
          :short_message => "Ping",
          :version => "1.0",
          :timestamp => Time.now.to_i
        }.to_json

        p [ :sending, data ]
        exchange.publish data, :routing_key => 'graylog.gelf'
      }
    end
  end
end
