FROM centos:7

# Install dependencies.
RUN curl -sL https://rpm.nodesource.com/setup_6.x | bash - && \
    yum install -y initscripts curl tar gcc libc6-dev git nodejs bzip2 freetype fontconfig urw-fonts

# Install Go.
# Note that 1.4 is needed first to build 1.9.
ENV GOLANG_VERSION 1.4
RUN curl -sSL https://golang.org/dl/go$GOLANG_VERSION.src.tar.gz \
                | tar -v -C /tmp -xz

RUN cd /tmp/go/src && ./make.bash --no-clean 2>&1
ENV GOROOT_BOOTSTRAP /tmp/go
ENV GOLANG_VERSION 1.9

RUN curl -sSL https://golang.org/dl/go$GOLANG_VERSION.src.tar.gz \
                | tar -v -C /usr/src -xz

RUN cd /usr/src/go/src && ./make.bash 2>&1
ENV PATH /usr/src/go/bin:$PATH

RUN mkdir -p /go/src /go/bin && chmod -R 777 /go && rm -rf /tmp/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH

# Set up Grafana source in Go source.
RUN git clone https://github.com/grafana/grafana.git /go/src/github.com/grafana/grafana

WORKDIR /go/src/github.com/grafana/grafana

# Grab the fork that contains the functionality.
RUN git remote add fork https://github.com/saurabhmaurya15/kirk-grafana.git && \
    git fetch fork && \
    git checkout fork/feature/elasticsearch-alerting

# Build Grafana.
RUN go run build.go setup && \
    go run build.go build && \
    npm install -g yarn && \
    yarn install --pure-lockfile && \
    npm run build

# Install some plugins.
RUN bin/grafana-cli plugins install raintank-worldping-app && \
    bin/grafana-cli plugins install grafana-worldmap-panel && \
    bin/grafana-cli plugins install grafana-clock-panel && \
    bin/grafana-cli plugins install grafana-piechart-panel && \
    bin/grafana-cli plugins install grafana-simple-json-datasource &&\
    bin/grafana-cli plugins install vonage-status-panel && \
    bin/grafana-cli plugins install briangann-datatable-panel && \
    bin/grafana-cli plugins install briangann-gauge-panel

ENV GF_PATHS_PLUGINS /var/lib/grafana/plugins
CMD bin/grafana-server
EXPOSE 3000
ENTRYPOINT bin/grafana-server
