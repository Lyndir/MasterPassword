FROM debian:buster-slim

# For i386
#FROM i386/debian:buster-slim
#ENTRYPOINT ["linux32", "--"]

# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=863199
RUN mkdir -p /usr/share/man/man1

RUN apt-get update && apt-get install openjdk-10-jdk-headless git-core bash libtool automake autoconf make g++
RUN git clone --depth=3 $(: --shallow-submodules) --recurse-submodules https://gitlab.com/MasterPassword/MasterPassword.git /mpw
RUN cd /mpw/gradle && ./gradlew -i clean build
