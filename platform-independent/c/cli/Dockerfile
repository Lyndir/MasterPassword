FROM ubuntu
WORKDIR /mpw/cli
ADD . /mpw

RUN apt-get update && apt -y install cmake libsodium-dev libjson-c-dev libncurses-dev libxml2-dev
RUN cmake -DBUILD_MPW_TESTS=ON . && make install
RUN mpw-tests

CMD mpw
