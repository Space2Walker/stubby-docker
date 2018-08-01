FROM debian:stretch as builder
LABEL maintainer="Matthew Vance"

ENV VERSION_OPENSSL=openssl-1.1.0h \
    SHA256_OPENSSL=5835626cde9e99656585fc7aaa2302a73a7e1340bf8c14fd635a62c66802a517 \
    SOURCE_OPENSSL=https://www.openssl.org/source/ \
    GPG_OPENSSL=8657ABB260F056B1E5190839D9C4D26D0E604491

WORKDIR /tmp/src

RUN set -e -x && \
    BUILD_DEPS='build-essential ca-certificates curl dirmngr gnupg libidn2-0-dev libssl-dev' && \
    DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
      $BUILD_DEPS && \
    curl -L $SOURCE_OPENSSL$VERSION_OPENSSL.tar.gz -o openssl.tar.gz && \
    echo "${SHA256_OPENSSL} ./openssl.tar.gz" | sha256sum -c - && \
    curl -L $SOURCE_OPENSSL$VERSION_OPENSSL.tar.gz.asc -o openssl.tar.gz.asc && \
    export GNUPGHOME="$(mktemp -d)" && \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_OPENSSL" && \
    gpg --batch --verify openssl.tar.gz.asc openssl.tar.gz && \
    tar xzf openssl.tar.gz && \
    cd $VERSION_OPENSSL && \
    make clean && \
    ./config --prefix=/opt/openssl no-weak-ssl-ciphers no-ssl3 no-shared enable-ec_nistp_64_gcc_128 -DOPENSSL_NO_HEARTBEATS -fstack-protector-strong && \
    make depend && \
    make && \
    make install_sw && \
    apt-get purge -y --auto-remove \
      $BUILD_DEPS && \
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

FROM debian:stretch 

EXPOSE 8053/udp

WORKDIR /tmp/src

COPY --from=builder /opt/openssl /opt/openssl

RUN set -e -x && \
    BUILD_DEPS='autoconf build-essential ca-certificates dh-autoreconf git libssl-dev libtool-bin libyaml-dev make m4' && \
    DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
      $BUILD_DEPS \
      dns-root-data \
      dnsutils \
      libev4 \
      libevent-core-2.0.5 \
      libidn11 \
      libuv1 \
      libyaml-0-2 && \
    git clone https://github.com/getdnsapi/getdns.git --branch master && \
    cd getdns && \
    git submodule update --init && \
    libtoolize -ci && \
    autoreconf -fi && \
    mkdir build && \
    cd build && \
    ../configure --prefix=/opt/stubby --without-libidn --without-libidn2 --enable-stub-only --with-ssl=/opt/openssl --with-stubby && \
    make && \
    make install && \
    groupadd -r stubby && \
    useradd --no-log-init -r -g stubby stubby && \
    apt-get purge -y --auto-remove \
      $BUILD_DEPS && \
    rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*

WORKDIR /opt/stubby

ENV PATH /opt/stubby/bin:$PATH

USER stubby:stubby

COPY stubby.yml /opt/stubby/etc/stubby/stubby.yml

HEALTHCHECK CMD dig @127.0.0.1 -p 8053 google.com || exit 1

CMD ["/opt/stubby/bin/stubby", "-l"]