# Under FrieNDA, rights granted by audibleblink
# DO NOT DISTRIBUTE

FROM ruby:2.6-alpine

WORKDIR /app
COPY . /app
RUN bundle update
CMD 'ruby server.rb'
