module Partyhat
  class Reader < EventMachine::FileTail
    def initialize( path, config )
      super( path, 1 )

      DaemonKit.logger.info "Tailing #{path}"
      @buffer = BufferedTokenizer.new
      @host = config['host']
    end

    def receive_data(data)
      @buffer.extract(data).each do |line|
        
        gelf = {
          :version => "1.0",
          :host => @host,
          :timestamp => Time.now.to_i,
          :short_message => line
        }
      end
    end
  end
end
