# Remove old pids
rm -f tmp/pids/server.pid
rm -f /run/nginx.pid

# Start nginx
nginx
# Start puma
bundle exec puma -C /app/config/puma.rb
