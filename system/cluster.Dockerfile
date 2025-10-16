################# Variables ################
ARG ELIXIR_VERSION=1.17.3
ARG OTP_VERSION=27.0.1
ARG DEBIAN_VERSION=bookworm-20250630-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} AS builder

# Install build dependencies
RUN apt-get update -y && \
    apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y pkg-config openssl build-essential git protobuf-compiler nodejs && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*

# prepare build dir
WORKDIR /build_space

# install hex + rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# install protoc-gen-elixir
RUN mix escript.install hex protobuf --force

# set build ENV
ARG MIX_ENV=prod
ENV MIX_ENV=prod

ENV OTPROOT=/usr/lib/erlang
ENV ERL_LIBS=/usr/lib/erlang/lib
ENV PATH="/root/.mix/escripts:${PATH}"

# copy umbrella configuration
COPY mix.exs mix.lock ./
COPY config/config.exs config/prod.exs config/runtime.exs config/

# copy umbrella apps
COPY apps/apis apps/apis/
COPY apps/greenhouse_tycoon apps/greenhouse_tycoon/
COPY apps/greenhouse_tycoon_web apps/greenhouse_tycoon_web/

# install mix dependencies and generate protobuf code
RUN MIX_ENV="prod" mix do deps.get --only "prod", deps.update --all, deps.compile

# Clone Heroicons (if needed for web interface)
RUN rm -rf deps/heroicons && \
    mkdir -p deps/heroicons && \
    cd deps/heroicons && \
    git init && \
    git remote add origin https://github.com/tailwindlabs/heroicons.git && \
    git fetch --depth 1 origin v2.1.1 && \
    git checkout FETCH_HEAD

# Install npm dependencies and build assets
WORKDIR /build_space/apps/greenhouse_tycoon_web/assets
RUN npm install || true

WORKDIR /build_space
# Ensure mix.digest runs in prod (if assets exist)
RUN NODE_ENV=production mix assets.deploy || true

# compile project
RUN MIX_ENV="prod" mix compile && \
MIX_ENV="prod" mix release greenhouse_tycoon

########### RUNTIME ###############
# prepare release image
FROM ${RUNNER_IMAGE} AS greenhouse_tycoon

RUN apt-get update -y && \
  apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates libc6 curl procps && \
  apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /app

# Create directories
RUN mkdir -p /app/data
RUN mkdir -p /system

# Set ownership
RUN chown nobody /app
RUN chown nobody /app/data
RUN chown nobody /system

# Copy release from builder
COPY --from=builder --chown=nobody /build_space/_build/prod/rel/greenhouse_tycoon .

# Create health check script
RUN echo '#!/bin/bash\n\
set -e\n\
echo "Health check for Greenhouse Tycoon..."\n\
# Check if the main HTTP port is responding\n\
curl -f http://localhost:${PORT:-4002}/health || exit 1\n\
echo "Greenhouse Tycoon is healthy"' > /system/check-greenhouse-tycoon.sh

RUN chmod +x /system/check-greenhouse-tycoon.sh
RUN chown nobody /system/check-greenhouse-tycoon.sh

USER nobody

ENV HOME=/app
ENV MIX_ENV="prod"

# Default environment variables
ENV GH_TYC_SECRET_KEY_BASE="changeme"
ENV PORT="4002"

# Cluster configuration defaults
ENV GH_TYC_STORE_ID="greenhouse_tycoon"
ENV GH_TYC_DB_TYPE="cluster"
ENV GH_TYC_TIMEOUT="15000"
ENV GH_TYC_STORE_DESCRIPTION="Greenhouse Tycoon Event Store"
ENV GH_TYC_STORE_TAGS="greenhouse,iot,business"
ENV GH_TYC_DATA_DIR="/app/data"

# Cluster configuration
ENV GH_TYC_CLUSTER_PORT="45892"
ENV GH_TYC_CLUSTER_IF_ADDR="*******"
ENV GH_TYC_CLUSTER_MULTICAST_ADDR="***********"
ENV GH_TYC_CLUSTER_SECRET="unified_cluster_secret_2024"

# Expose ports
EXPOSE 4002
EXPOSE 4369
EXPOSE 9100

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD ["/system/check-greenhouse-tycoon.sh"]

ENTRYPOINT ["/app/bin/greenhouse_tycoon"]
CMD ["start"]
