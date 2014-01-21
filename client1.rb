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

puts "publishing events once a second"

n = 0
while true
  x.publish("Hello! Iteration: #{n += 1}", :routing_key => q.name)
  sleep 1
end

