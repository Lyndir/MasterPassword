FROM alpine
WORKDIR /mpw/gradle
ADD . /mpw

RUN apk update && apk add libtool automake autoconf make g++ openjdk8
RUN ./gradlew -i build
