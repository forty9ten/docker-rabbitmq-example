require "bunny"

trap("INT") { terminate_clean if !@interrupted }
trap("TERM") { terminate_clean if !@interrupted }

def terminate_clean
  puts "terminating cleanly"
  @conn.close
  exit
end

@conn = Bunny.new :host => ENV["RABBITMQ_PORT_5672_TCP_ADDR"],
                  :port => ENV["RABBITMQ_PORT_5672_TCP_PORT"]
@conn.start

ch = @conn.create_channel
q  = ch.queue("bunny.examples.hello_world", :auto_delete => true)
x  = ch.default_exchange

q.subscribe do |delivery_info, metadata, payload|
  puts "Received #{payload}"
end

while true
  sleep 1
end
