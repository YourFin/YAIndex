FROM ruby:2.6.4

ENV RAILS_ON_DOCKER=yes

# Install nodejs 11
RUN curl -sL https://deb.nodesource.com/setup_11.x | bash - && \
  apt-get install -y nodejs

# Install yarn
RUN npm install --global yarn

# cd into /app
ENV APP_PATH=/app

# Install gems
RUN mkdir -p $APP_PATH
COPY Gemfile ${APP_PATH}/Gemfile
COPY Gemfile.lock ${APP_PATH}/Gemfile.lock
WORKDIR ${APP_PATH}
RUN bundle install

COPY package.json ${APP_PATH}/package.json
COPY yarn.lock ${APP_PATH}/yarn.lock
RUN yarn install --check-files

# Copy application files
COPY . ${APP_PATH}

COPY bin/entrypoint.sh /usr/bin
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
