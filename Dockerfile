FROM elm as elmbuild

FROM alpine:latest

COPY --from=elmbuild /bin/elm /bin/elm

RUN apk update && apk add gmp ncurses-libs nodejs libffi ruby ruby-bundler ruby-json ruby-webrick ruby-dev make

COPY src /opt/app/src
COPY assets /opt/app/assets
COPY elm.json /opt/app/
COPY backend /opt/app/
#COPY Gemfile /opt/app/
COPY index.html /opt/app/

WORKDIR /opt/app

#RUN bundler
RUN elm make src/Main.elm --output=assets/Main.js

