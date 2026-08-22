FROM haskell:9.10.3-slim-bookworm AS builder

WORKDIR /mcrypt

COPY . .

RUN cabal update
RUN cabal build --only-dependencies
RUN cabal build 

CMD bash
