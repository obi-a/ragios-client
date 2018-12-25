FROM ruby:2.4.1-stretch
RUN apt-get update
COPY . /usr/src/ragios-client
WORKDIR /usr/src/ragios-client
RUN bundle install
