
FROM alpine

RUN apk update
RUN apk upgrade

RUN apk add elm
