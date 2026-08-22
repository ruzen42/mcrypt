# Stage 1
FROM debian:bookworm-slim AS liboqs-builder
 
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ninja-build \
    git \
    libssl-dev \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*
 
ARG LIBOQS_TAG=0.16.0
 
RUN git clone --depth 1 --branch ${LIBOQS_TAG} \
      https://github.com/open-quantum-safe/liboqs.git /tmp/liboqs \
 && cmake -G Ninja -S /tmp/liboqs -B /tmp/liboqs/build \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_INSTALL_PREFIX=/opt/liboqs \
      -DOQS_BUILD_ONLY_LIB=ON \
      -DOQS_MINIMAL_BUILD="SIG_ml_dsa_65" \
 && ninja -C /tmp/liboqs/build \
 && ninja -C /tmp/liboqs/build install \
 && strip --strip-unneeded /opt/liboqs/lib/liboqs.so* \
 && rm -rf /tmp/liboqs
 
# Stage 2
FROM haskell:9.10.3-slim-bookworm AS builder
 
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    libssl-dev \
 && rm -rf /var/lib/apt/lists/*
 
COPY --from=liboqs-builder /opt/liboqs /usr/local
 
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig \
    C_INCLUDE_PATH=/usr/local/include \
    LIBRARY_PATH=/usr/local/lib \
    LD_LIBRARY_PATH=/usr/local/lib
 
WORKDIR /mcrypt
 
COPY *.cabal cabal.project* ./
RUN --mount=type=cache,target=/root/.local/state/cabal,sharing=locked \
    --mount=type=cache,target=/root/.cache/cabal,sharing=locked \
    cabal update && cabal build --only-dependencies
 
COPY . .
RUN --mount=type=cache,target=/root/.local/state/cabal,sharing=locked \
    --mount=type=cache,target=/root/.cache/cabal,sharing=locked \
    --mount=type=cache,target=/mcrypt/dist-newstyle,sharing=locked \
    cabal build all \
 && mkdir -p /out/bin \
 && cp "$(cabal list-bin exe:mcrypt)" /out/bin/mcrypt \
 && cp "$(cabal list-bin exe:mkey)"   /out/bin/mkey \
 && strip /out/bin/mcrypt /out/bin/mkey
 
# Stage 3
FROM debian:bookworm-slim AS runtime
 
RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl3 \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -r -u 1000 -m -d /home/mcrypt -s /usr/sbin/nologin mcrypt
 
COPY --from=liboqs-builder /opt/liboqs/lib/liboqs.so* /usr/local/lib/
RUN ldconfig
 
COPY --from=builder /out/bin/mcrypt /usr/local/bin/mcrypt
COPY --from=builder /out/bin/mkey   /usr/local/bin/mkey
 
USER mcrypt
WORKDIR /work
 
ENTRYPOINT ["mcrypt"]
CMD ["--help"]
