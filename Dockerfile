FROM golang:1.21-alpine3.19 AS build
ARG TARGETARCH

ARG consul_version=1.18.1
ADD https://releases.hashicorp.com/consul/${consul_version}/consul_${consul_version}_linux_${TARGETARCH}.zip /usr/local/bin
RUN cd /usr/local/bin && unzip consul_${consul_version}_linux_${TARGETARCH}.zip

ARG vault_version=1.16.0
ADD https://releases.hashicorp.com/vault/${vault_version}/vault_${vault_version}_linux_${TARGETARCH}.zip /usr/local/bin
RUN cd /usr/local/bin && unzip vault_${vault_version}_linux_${TARGETARCH}.zip

RUN apk update && apk add --no-cache git
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go test -mod=vendor -trimpath -ldflags "-s -w" ./...
RUN CGO_ENABLED=0 go build -mod=vendor -trimpath -ldflags "-s -w"

FROM alpine:3.19
RUN apk update && apk add --no-cache ca-certificates
COPY --from=build /src/fabio /usr/bin
ADD fabio.properties /etc/fabio/fabio.properties
EXPOSE 9998 9999
ENTRYPOINT ["/usr/bin/fabio"]
CMD ["-cfg", "/etc/fabio/fabio.properties"]
