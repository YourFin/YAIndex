FROM ubuntu:eoan

# cd into /app
ENV APP_PATH=/app

# Install nodejs 13
RUN curl -sL https://deb.nodesource.com/setup_13.x | sudo -E bash - && \
  apt-get install -y nodejs

#Install nginx
RUN apt-get install -y nginx

# Install yarn
RUN npm install --global pnpm

COPY package.json ${APP_PATH}/package.json
COPY pnpm-lock.yaml ${APP_PATH}/yarn.lock
RUN pnpm install

# Copy over entrypoint
COPY bin/entrypoint.sh /usr/bin
RUN chmod +x /usr/bin/entrypoint.sh

# Configure nginx
RUN useradd -ms /bin/false nginx
RUN ln -sf ${APP_PATH}/nginx/nginx.conf /etc/nginx/nginx.conf

# Copy application files
COPY . ${APP_PATH}

# Attempt to build elm packages to pull in dependencies
RUN bash -c "${APP_PATH}/node_modules/elm/bin/elm make /app/javascript/Main.elm --output=/dev/null 2>/dev/null || true"

ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

CMD ["./bin/run-dev.sh"]
