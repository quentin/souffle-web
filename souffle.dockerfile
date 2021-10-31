
FROM alpine:latest

RUN apk update
RUN apk upgrade
RUN apk add git make cmake bison flex g++ git sqlite sqlite-dev zlib zlib-dev ncurses-libs ncurses-dev libffi-dev libc6-compat libgomp


WORKDIR /tmp
RUN git clone --depth 1 --branch sh2ruby https://github.com/quentin/souffle.git

WORKDIR /tmp/souffle
#RUN sed -i -e "s/-e utf8 -W0/-E/g" src/main.cpp
#RUN sed -i -e "s/mcpp/gcc/g" src/main.cpp
#RUN sed -i -e "s/libsouffle PUBLIC OpenMP/libsouffle PRIVATE OpenMP/g" src/CMakeLists.txt
#RUN sed -i -e "s/libsouffle PUBLIC libffi/libsouffle PRIVATE libffi/g" src/CMakeLists.txt
#RUN sed -i -e "s/libsouffle PUBLIC LibFFI::LibFFI/libsouffle PRIVATE LibFFI::LibFFI/g" src/CMakeLists.txt

RUN mkdir build; \
    cd build; \
    cmake .. \
      -DSOUFFLE_BASH_COMPLETION=OFF \
      -DSOUFFLE_DOMAIN_64BIT=ON \
      #-DCMAKE_EXE_LINKER_FLAGS="-static -static-libgcc -static-libstdc++" \
      #-DCMAKE_FIND_LIBRARY_SUFFIXES=".a" \
      ; \
    make souffle -j"$(grep -c ^processor /proc/cpuinfo)"; \
    make install

