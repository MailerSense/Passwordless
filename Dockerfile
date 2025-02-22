ARG ELIXIR_VERSION=1.18.2
ARG OTP_VERSION=27.2
ARG DEBIAN_VERSION=bookworm-20250113-slim

ARG NODE_IMAGE="node:lts-bookworm-slim"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"
ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"

########################################
# 1. Get deps
########################################
FROM ${BUILDER_IMAGE} AS deps

# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# require the auth key for private repos
ARG OBAN_PRO_AUTH_KEY

# add the private petal repo
RUN mix hex.repo add oban https://getoban.pro/repo \
    --fetch-public-key SHA256:4/OSKi0NRF91QVVXlGAhb/BIMLnK8NHcx/EWs+aIWPc \
    --auth-key ${OBAN_PRO_AUTH_KEY}

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

########################################
# 2. Build Assets
########################################
FROM ${NODE_IMAGE} AS assets

# enable pnpm
ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN npm install -g corepack@latest && corepack enable

WORKDIR /app

# copy over deps which contains certain frontend assets
COPY --from=deps /app/deps ./deps
COPY assets assets

# set node env
ENV NODE_ENV=prod

# install npm dependencies
RUN cd assets && pnpm install

########################################
# 3. Build Rust
########################################
FROM rust:latest AS rust

# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

WORKDIR /app 
COPY native/passwordless_native ./

RUN cargo rustc --release  

########################################
# 4. Build Elixir
########################################
FROM deps AS builder

WORKDIR /app

COPY lib lib
COPY priv priv
COPY --from=assets app/assets assets

# copy compiled rust binary
COPY --from=rust /app/target/release/libpasswordless_native.so priv/native/libpasswordless_native.so

# compile assets
RUN mix assets.setup
RUN mix assets.deploy

# compile the release
RUN mix compile

# changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/
COPY rel rel

RUN mix sentry.package_source_code
RUN mix release

########################################
# 5. Build release image
########################################
# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}

# set the locale
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN export LANG=en_US.UTF-8 \
    && echo $LANG UTF-8 > /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=$LANG

WORKDIR /app
RUN chown nobody /app
RUN mkdir -p /app/lib/tzdata-1.1.2/priv/*
RUN chown nobody /app/lib/tzdata-1.1.2/priv/*
RUN chmod ugo+rw /app/lib/tzdata-1.1.2/priv/*

# set runner ENV
ENV MIX_ENV="prod"

# only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/passwordless ./

USER nobody

EXPOSE 8000

CMD ["/app/bin/server"]