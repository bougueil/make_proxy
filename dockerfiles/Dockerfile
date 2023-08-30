ARG ELIXIR_VERSION=1.15.0
ARG OTP_VERSION=26.0.2
ARG DEBIAN_VERSION=bullseye-20230612-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} as builder
ARG WORKER_TYPE
ENV WORKER_TYPE=${WORKER_TYPE}

# install build dependencies
RUN apt-get update -y\
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# prepare build dir
WORKDIR /app
# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config


# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY lib lib
COPY src src
COPY include include

# Compile the release
RUN mix release
CMD ["./_build/prod/rel/make_proxy/bin/make_proxy", "start"]
