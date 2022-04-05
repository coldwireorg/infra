FROM alpine
RUN echo "https://mirror.sr.ht/alpine/v3.14/sr.ht" >> /etc/apk/repositories
RUN wget -q -O /etc/apk/keys/alpine@sr.ht.rsa.pub https://mirror.sr.ht/alpine/alpine@sr.ht.rsa.pub
RUN apk update
RUN apk add git.sr.ht