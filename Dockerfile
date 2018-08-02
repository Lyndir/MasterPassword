FROM debian:stable-slim

# For i386
#FROM i386/debian:stable-slim
#ENTRYPOINT ["linux32", "--"]

# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=863199
RUN mkdir -p /usr/share/man/man1

RUN apt-get update && apt-get install -y default-jdk-headless git-core bash libtool automake autoconf make g++
RUN git clone --depth=3 $(: --shallow-submodules) --recurse-submodules https://gitlab.com/MasterPassword/MasterPassword.git /mpw
RUN cd /mpw/gradle && ./gradlew -i clean build
