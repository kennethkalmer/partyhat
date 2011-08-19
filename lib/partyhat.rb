# Your starting point for daemon specific classes. This directory is
# already included in your load path, so no need to specify it.

module Partyhat

  autoload :Listener, 'partyhat/listener'

  class << self

    def run!
      config = DaemonKit::Config.load('amqp').to_h(true)
      DaemonKit.logger.info "AMQP settings: #{config.inspect}"

      AMQP.start( config ) do |connection|

        DaemonKit.logger.info "AMQP connected, starting listener"
        Partyhat::Listener.start( connection )

      end
    end

  end
end
