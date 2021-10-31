FROM elm as elmbuild
WORKDIR /app

COPY src /app/src
COPY elm.json /app/elm.json

RUN /bin/elm make src/Main.elm --output=assets/Main.js

FROM souffle
RUN apk update && apk add ruby ruby-bundler ruby-json ruby-webrick libffi-dev graphviz
#  zlib sqlite sqlite-libs libgomp ncurses-libs libffi libstdc++ libgcc

COPY assets /app/assets
COPY backend /bin/backend
COPY index.html /app/index.html

#COPY --from=soufflebuild /usr/local/include/souffle /include/souffle
#COPY --from=soufflebuild /usr/local/bin/souffle /bin/souffle
#COPY --from=soufflebuild /usr/local/bin/souffle-compile /bin/souffle-compile

WORKDIR /app
EXPOSE 12000
ENTRYPOINT ["/bin/backend"]
CMD ["--souffle-bin","/usr/local/bin/souffle"]

