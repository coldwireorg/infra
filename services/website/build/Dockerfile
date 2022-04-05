FROM klakegg/hugo:0.95.0-alpine
WORKDIR /src
RUN apk add git
RUN git init && \
    git remote add origin https://codeberg.org/coldwire/website.git && \
    git pull origin main

EXPOSE 1313
CMD ["server"]