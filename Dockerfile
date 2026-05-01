FROM ruby:3.3-slim

RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs npm git libyaml-dev pkg-config \
      chromium chromium-driver \
      librsvg2-bin imagemagick && \
    npm install -g corepack && \
    corepack enable

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile

COPY . .

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
