ARG REPO_LOCATION
FROM ${REPO_LOCATION}ubuntu:focal AS builder

# Prevents TZ data prompt
ENV DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC

RUN apt-get update -y && \
    apt-get install -y git sudo tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Clone the repo
WORKDIR /workspace
RUN git clone https://github.com/facebook/mcrouter.git
WORKDIR /workspace/mcrouter

# Install mcrouter from source
RUN mkdir -p /build
RUN mcrouter/scripts/install_ubuntu_20.04.sh /build

# Get all the linked libraries for mcrouter and copy them to /lib
RUN ldd /build/install/bin/mcrouter | grep "=> /" | awk '{print $3}' | xargs -I '{}' cp -v '{}' /build/install/lib

FROM ${REPO_LOCATION}ubuntu:focal
ENV LD_LIBRARY_PATH=/mcrouter/lib
WORKDIR /mcrouter
COPY --from=builder /build/install /mcrouter
RUN ln -s /mcrouter/bin/mcrouter /usr/local/bin/mcrouter
RUN mcrouter --help

USER 1000:1000
CMD ["mcrouter", "--version"]