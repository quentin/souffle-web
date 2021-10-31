FROM alpine:3.10
RUN apk add --update ghc cabal git musl-dev zlib-dev ncurses-dev ncurses-static wget

WORKDIR /tmp
RUN git clone -b master https://github.com/elm/compiler.git

WORKDIR /tmp/compiler
RUN git checkout 0.19.1
RUN rm worker/elm.cabal
RUN cabal new-update
RUN cabal new-configure --disable-executable-dynamic --ghc-option=-optl=-static --ghc-option=-optl=-pthread
RUN cabal new-build
RUN strip -s ./dist-newstyle/build/x86_64-linux/ghc-*/elm-0.19.1/x/elm/build/elm/elm
RUN cp ./dist-newstyle/build/x86_64-linux/ghc-*/elm-0.19.1/x/elm/build/elm/elm /bin/elm
