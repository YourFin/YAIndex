FROM ubuntu:eoan

# cd into /app
ENV APP_PATH=/app

#Install nginx
RUN apt-get update
RUN apt-get install -y nginx curl

# Install nodejs 13
RUN curl -sL https://deb.nodesource.com/setup_13.x | bash - && \
  apt-get install -y nodejs


# Install pnpm
RUN npm install --global pnpm

WORKDIR ${APP_PATH}

COPY package.json ${APP_PATH}/package.json
COPY pnpm-lock.yaml ${APP_PATH}/pnpm-lock.yaml
RUN pnpm install --frozen-lockfile

# Copy over entrypoint
COPY bin/entrypoint.sh /usr/bin
RUN chmod +x /usr/bin/entrypoint.sh

# Configure nginx
RUN useradd -ms /bin/false nginx
RUN ln -sf ${APP_PATH}/nginx/nginx-dev.conf /etc/nginx/nginx.conf

# Copy application files
COPY . ${APP_PATH}

# Attempt to build elm packages to pull in dependencies
RUN bash -c "${APP_PATH}/node_modules/elm/bin/elm make /app/javascript/Main.elm --output=/dev/null 2>/dev/null || true"

ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

CMD ["./bin/run-dev.sh"]
