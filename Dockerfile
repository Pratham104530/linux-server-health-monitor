FROM ubuntu:24.04

LABEL maintainer="Linux Server Health Monitor"
LABEL description="Containerized Linux Server Health Monitor"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    coreutils \
    gawk \
    procps \
    util-linux \
    iproute2 \
    iputils-ping \
    dnsutils \
    grep \
    findutils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY health_check.sh .
COPY run_monitor.sh .
COPY cleanup.sh .
COPY config/ ./config/
COPY lib/ ./lib/

RUN chmod +x health_check.sh run_monitor.sh cleanup.sh

RUN mkdir -p reports logs

CMD ["./health_check.sh"]
