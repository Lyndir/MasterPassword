FROM alpine

# For i386
#FROM i386/alpine
#ENTRYPOINT ["linux32", "--"]

RUN apk add --no-cache git libtool automake autoconf make g++ bash openjdk8
RUN git clone --depth=3 $(: --shallow-submodules) --recurse-submodules https://gitlab.com/MasterPassword/MasterPassword.git /mpw
RUN cd /mpw/gradle && ./gradlew -i clean build
