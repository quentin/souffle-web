
# Use 3.13 because there is a compatibility issue between old versions of Docker (<20) and CMake
# see https://gitlab.alpinelinux.org/alpine/aports/-/issues/12321
#
# A possible workaround is described here: https://wiki.alpinelinux.org/wiki/Release_Notes_for_Alpine_3.13.0#time64_requirements
FROM alpine:3.13

RUN apk update
RUN apk upgrade
RUN apk add git make cmake bison flex gcc g++ git sqlite sqlite-dev zlib zlib-dev ncurses-libs ncurses-dev libffi-dev libc6-compat libgomp python3


WORKDIR /tmp
RUN git clone --depth 1 --branch master https://github.com/souffle-lang/souffle.git

WORKDIR /tmp/souffle
#RUN sed -i -e "s/-e utf8 -W0/-x c -E/g" src/main.cpp
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

