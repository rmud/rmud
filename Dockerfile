# docker build -t rmud:0.1.0 .
# docker run -v "$(pwd)/../rmud-data":/rmud-data -v "$(pwd)/../rmud-live":/rmud-live -p 3040:3040 -p 4040:4040 --rm rmud:0.1.0 ./rmud
# docker save rmud:0.1.0 | gzip > rmud_0_1_0.tgz
# docker load -i rmud_0_1_0.tgz

# Build image

FROM --platform=linux/amd64 ubuntu:20.04 as builder
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get -qq update && apt-get -y install \
  binutils \
  git \
  gnupg2 \
  libc6-dev \
  libcurl4 \
  libedit2 \
  libgcc-9-dev \
  libpython2.7 \
  libsqlite3-0 \
  libstdc++-9-dev \
  libxml2 \
  libz3-dev \
  pkg-config \
  tzdata \
  uuid-dev \
  zlib1g-dev \
  \
  curl \
  \
  && rm -r /var/lib/apt/lists/*

ENV SWIFTENV_ROOT /usr/local
# Redownloads each time
#ADD https://github.com/kylef/swiftenv/archive/1.4.0.tar.gz /tmp/swiftenv.tar.gz
RUN curl -L -o /tmp/swiftenv.tar.gz https://github.com/kylef/swiftenv/archive/1.4.0.tar.gz
RUN tar -xzf /tmp/swiftenv.tar.gz -C /usr/local/ --strip 1
ENV PATH /usr/local/shims:$PATH
RUN swiftenv install https://download.swift.org/swift-5.7.2-release/ubuntu2004/swift-5.7.2-RELEASE/swift-5.7.2-RELEASE-ubuntu20.04.tar.gz

WORKDIR /app
COPY . .
RUN mkdir -p /build/lib && cp -R /usr/local/versions/5.7.2-RELEASE/usr/lib/swift/linux/*.so* /build/lib
RUN swift build -c release && mv `swift build -c release --show-bin-path` /build/bin
RUN cp -R Tools /build/bin/

# Production image

FROM --platform=linux/amd64 ubuntu:20.04
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get -qq update && apt-get -y install \
  php7.4 php7.4-common php7.4-cli php7.4-mbstring \
  locales \
  && rm -r /var/lib/apt/lists/* \
  && locale-gen ru_RU.UTF-8
ENV LANG ru_RU.UTF-8
ENV LANGUAGE ru_RU:en
ENV LC_ALL ru_RU.UTF-8
WORKDIR /rmud
COPY --from=builder /build/bin/rmud .
COPY --from=builder /build/bin/Tools Tools
COPY --from=builder /build/lib/* /usr/lib/
EXPOSE 3040
EXPOSE 4040
CMD ["./rmud"]
