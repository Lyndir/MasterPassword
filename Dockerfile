FROM ubuntu

WORKDIR /bin

RUN apt update; apt -y install wget cmake libsodium-dev libjson-c-dev libncurses-dev
RUN wget https://ssl.masterpasswordapp.com/masterpassword-cli.tar.gz
RUN tar xvfz masterpassword-cli.tar.gz && rm masterpassword-cli.tar.gz &&\
        ./build

VOLUME /root/.mpw.d/

CMD /bin/mpw
