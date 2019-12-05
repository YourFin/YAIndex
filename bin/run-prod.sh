# Make sure pids folder exists
mkdir -p tmp/pids

# Remove old pids
rm -f tmp/pids/server.pid
rm -f /run/nginx.pid

# Start nginx
nginx
# Start puma
bundle exec puma -b "tcp://localhost" -C /app/config/puma.rb
