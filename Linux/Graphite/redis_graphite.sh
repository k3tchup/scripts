#!/usr/bin/env ruby
require 'socket'

# modified from: https://gist.github.com/somebox/7039510
# This script runs every minute, captures stats about redis
# and forwards them to graphite as counter values.

# Graphite/carbon settings
GRAPHITE_HOST="localhost"
GRAPHITE_PORT=2003

def instrument_redis(redis_host)
    fqdn = Socket.gethostname
    host = fqdn.split('.')[0]
    namespace = "path.to.carbon.#{host}.redis"
    redis = {}
    `/usr/bin/redis-cli -h #{redis_host} info`.each_line do |line|
        key,value = line.chomp.split(/:/)
        redis[key]=value
        send_data("#{namespace}.#{key}", value.to_i)
    end
end

def send_data(path, value, time=nil)
    time ||= Time.new
    msg = "#{path} #{value} #{time.to_i}\n"
    puts msg
    @socket.send(msg, 0)
    msg
end


# do stuff
@socket = TCPSocket.new(GRAPHITE_HOST, GRAPHITE_PORT)
instrument_redis('localhost')
@socket.close

