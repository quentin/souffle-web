
FROM alpine

RUN apk update
RUN apk upgrade

RUN apk add git
#RUN git clone --depth 1 https://github.com/souffle-lang/souffle.git
RUN git clone --branch lsbrelease --depth 1 https://github.com/quentin/souffle.git

RUN apk search -v '*libc*'

RUN apk add make cmake bison flex g++ git sqlite sqlite-dev zlib zlib-dev ncurses-libs ncurses-dev libffi-dev bash-completion libc6-compat

RUN cd souffle; \
    mkdir build; \
    cd build; \
    cmake .. -DSOUFFLE_BASH_COMPLETION=OFF -DSOUFFLE_ENABLE_PACKAGE=OFF; \
    make -j"$(grep -c ^processor /proc/cpuinfo)"; \
    make install

ENTRYPOINT ["souffle"]
