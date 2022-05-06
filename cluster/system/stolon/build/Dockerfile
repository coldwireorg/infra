FROM golang:1.17.6 AS builder
WORKDIR /stolon
RUN git clone https://github.com/sorintlab/stolon .
RUN git pull && git checkout v0.17.0
RUN go mod download
RUN make && chmod +x /stolon/bin/*

FROM postgres:14.2
COPY --from=builder /stolon/bin /usr/local/bin
USER postgres
ENTRYPOINT []
CMD ["/bin/bash"]