# Set up a container for doing gradle cross-compiling.
#
# docker build -t lhunath/mp-gradle --file Dockerfile /var/empty
FROM debian:stable-slim

# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=863199
RUN mkdir -p /usr/share/man/man1

RUN apt-get update && apt-get install -y default-jdk-headless git-core bash libtool automake autoconf make g++-multilib
RUN git clone --depth=3 $(: --shallow-submodules) --recurse-submodules https://gitlab.com/MasterPassword/MasterPassword.git /mpw
RUN cd /mpw && ./gradlew -i clean
RUN cd /mpw && git pull && git log -1 && ./gradlew -i check
