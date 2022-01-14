FROM ubuntu:latest

WORKDIR /app

RUN apt update && apt install git make g++ bison flex -y

RUN git clone https://github.com/Makopo/lslint.git linter &&    \
    cd linter &&                                                \
    make
