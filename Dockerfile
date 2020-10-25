FROM ruby:2.7.2-alpine as builder

RUN apk update && apk upgrade
RUN apk add --update alpine-sdk sqlite-dev tzdata && rm -rf /var/cache/apk/*

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile* $APP_HOME/
ENV RAILS_ENV=production
ENV SECRET_KEY_BASE mykey
RUN bundle install --deployment --jobs=4 --without development test
COPY . $APP_HOME
RUN bundle exec rake assets:precompile
RUN rm -rf $APP_HOME/node_modules
RUN rm -rf $APP_HOME/tmp/*

FROM ruby:2.7.2-alpine
RUN apk update && apk add --update sqlite-dev tzdata && rm -rf /var/cache/apk/*

ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY --from=builder /app $APP_HOME
ENV RAILS_ENV=production

# TODO: In a production setting you'd use an environment variable for this value
ENV SECRET_KEY_BASE mykey
RUN bundle config --local path vendor/bundle

RUN bundle config --local without development:test:assets

EXPOSE 3000:3000
CMD rm -f tmp/pids/server.pid \
  && bundle exec rails db:migrate \
  && bundle exec rails s -b 0.0.0.0 -p 3000
