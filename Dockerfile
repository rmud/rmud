# docker build -t rmud:0.1.0 .
# docker run -v "$(PWD)/../rmud-data":/rmud-data -v "$(PWD)/../rmud-live":/rmud-live -p 3040:3040 -p 4040:4040 --rm rmud:0.1.0 ./rmud
# docker save rmud:0.1.0 | gzip > rmud_0_1_0.tgz
# docker load -i rmud_0_1_0.tgz

# Build image

FROM ubuntu:18.04 as builder
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get -qq update && apt-get -y install \
  libatomic1 \
  libedit2 \
  libsqlite3-0 \
  libcurl4 \
  libxml2 \
  libbsd0 \
  libc6-dev \
  binutils \
  libgcc-5-dev \
  libstdc++-5-dev \
  libpython2.7 \
  curl \
  tzdata \
  git \
  pkg-config \
  \
  lsb-release \
  \
  libbsd-dev \
  libssl-dev \
  zlib1g-dev \
  && rm -r /var/lib/apt/lists/*

ENV SWIFTENV_ROOT /usr/local
# Redownloads each time
#ADD https://github.com/kylef/swiftenv/archive/1.4.0.tar.gz /tmp/swiftenv.tar.gz
RUN curl -L -o /tmp/swiftenv.tar.gz https://github.com/kylef/swiftenv/archive/1.4.0.tar.gz
RUN tar -xzf /tmp/swiftenv.tar.gz -C /usr/local/ --strip 1
ENV PATH /usr/local/shims:$PATH
RUN swiftenv install 5.0

WORKDIR /app
COPY . .
RUN mkdir -p /build/lib && cp -R /usr/local/versions/5.0/usr/lib/swift/linux/*.so* /build/lib
RUN swift build -c release && mv `swift build -c release --show-bin-path` /build/bin
RUN cp -R Tools /build/bin/

# Production image

FROM ubuntu:18.04
ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get -qq update && apt-get -y install \
  libicu60 libxml2 libbsd0 libcurl4 libatomic1 \
  php7.2 php7.2-common php7.2-cli php7.2-mbstring \
  locales \
  && rm -r /var/lib/apt/lists/* \
  && locale-gen ru_RU.UTF-8
ENV LANG ru_RU.UTF-8
ENV LANGUAGE ru_RU:en
ENV LC_ALL ru_RU.UTF-8
COPY --from=builder /build/bin/rmud /rmud/
COPY --from=builder /build/bin/Tools /rmud/Tools
COPY --from=builder /build/lib/* /usr/lib/
WORKDIR /rmud
EXPOSE 3040
EXPOSE 4040
CMD ["./rmud"]
