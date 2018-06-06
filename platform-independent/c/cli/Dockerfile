FROM alpine
WORKDIR /mpw/cli
ADD . /mpw

RUN apk update && apk add cmake make gcc musl-dev ncurses-dev libsodium-dev json-c-dev libxml2-dev
RUN cmake -DBUILD_MPW_TESTS=ON . && make install
RUN mpw-tests

CMD mpw
