FROM ruby:2.7.2-alpine

RUN apk update && apk upgrade
RUN apk add --update alpine-sdk sqlite-dev tzdata && rm -rf /var/cache/apk/*

ENV APP_HOME /app
ENV RAILS_ENV=production
# TODO: In a production setting you'd use an environment variable for this value
ENV SECRET_KEY_BASE mykey

RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile* $APP_HOME/
RUN bundle config set without 'development test'
RUN bundle config set deployment 'true'
RUN bundle install

COPY . $APP_HOME
RUN bundle exec rake assets:precompile
RUN bundle config --local without development:test:assets

EXPOSE 3000:3000
CMD rm -f tmp/pids/server.pid \
  && bundle exec rails db:migrate \
  && bundle exec rails s -b 0.0.0.0 -p 3000
