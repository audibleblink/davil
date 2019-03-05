FROM ruby:2.6-alpine

WORKDIR /app
COPY . /app
RUN bundle update
CMD './server.rb'
