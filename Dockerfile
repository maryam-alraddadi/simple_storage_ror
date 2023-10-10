FROM ruby:3.2.2

ENV BUNDLER_VERSION=2.3.3
RUN gem install rails bundler

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle config build.nokogiri --use-system-libraries

RUN bundle check || bundle install


COPY . ./

ENTRYPOINT ["./entrypoints/docker-entrypoint.sh"]