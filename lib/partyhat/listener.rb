module Partyhat
  class Listener < EM::Connection
    
    class << self
      
      def start( amqp_connection )
        # Load our config
        config = {
          'host' => 'localhost',
          'port' => 51400
        }.merge DaemonKit::Config.load('partyhat')

        # Open an AMQP channel
        AMQP::Channel.new( amqp_connection ) do |channel|
          DaemonKit.logger.info "AMQP channel in place"

          # Setup a direct exchange
          channel.direct("logging") do |exchange|
            # Setup our queue and bind it so Graylog can use it
            channel.queue( 'graylog', :durable => true ).bind( exchange, :routing_key => 'graylog.gelf' )

            DaemonKit.logger.info "AMQP exchange in place"
            run!( config, exchange )
          end
        end
      end

      def run!( config, exchange )

        EM.start_server( config['host'], config['port'], self ) do |c|
          c.config = config
          c.exchange = exchange
        end
      end

    end

    attr_accessor :config
    attr_accessor :exchange

    def post_init
      DaemonKit.logger.info "Connection established"
      @buffer = BufferedTokenizer.new
    end

    def receive_data( data )
      @buffer.extract( data ).each do |line|
        DaemonKit.logger.debug "Processing: #{line}"
        process_syslog_message! line
      end
    end

    def process_syslog_message!( line )

      date = Time.parse( line[0,15] )
      parts = line[ 16, line.length ].split(' ', 3)

      data = {
        :host => "partyhat",
        :level => parts[0],
        :facility => parts[1],
        :short_message => parts[2],
        :version => "1.0",
        :timestamp => date.to_i
      }.to_json

      DaemonKit.logger.debug "Sending gelf: #{data}"
      self.exchange.publish( data, :routing_key => 'graylog.gelf' )
    end

  end
end
