# Ubuntu 24.04 + Qt6: required for GitHub release tarballs from 2.33 onward.
# Those releases ship UIC 6.x headers (#include <QtGui/QAction>). Older tags
# (2.32 and below) still ship Qt5 UIC headers and are gated in release.sh.
FROM ubuntu:24.04 AS build
LABEL maintainer="austin.millan@protonmail.com"
LABEL org.label-schema.name="docker-mandelbulber2"
LABEL org.label-schema.url="https://www.mandelbulber.com/"
LABEL org.label-schema.vcs-url="https://github.com/buddhi1980/mandelbulber2"
LABEL org.label-schema.description="Run Mandelbulber2 in a docker container."
LABEL org.label-schema.docker.cmd='docker run -e USER_UID=${id} -it --net=host --env="DISPLAY" -v $HOME/.mandelbulber:/root/.mandelbulber:rw -v $HOME/.Xauthority:/root/.Xauthority:rw --entrypoint="mandelbulber2" registry.gitlab.com/mandelbulber/mandelbulber2-ubuntu:2.34'
LABEL org.label-schema.docker.cmd.help="docker run -e USER_UID=${id} -it --entrypoint=\"mandelbulber2\" registry.gitlab.com/mandelbulber/mandelbulber2-ubuntu:2.34 --help"
LABEL org.label-schema.docker.build='docker build --build-arg VERSION=2.34 -t austin-millan/mandelbulber2:local .'

ENV DEBIAN_FRONTEND=noninteractive

# Compile packages aligned with upstream mandelbulber2/deploy/README (Ubuntu 24.04).
RUN apt-get update && apt-get install --no-install-recommends -y \
    build-essential \
    ca-certificates \
    curl \
    desktop-file-utils \
    jq \
    libgomp1 \
    libgsl-dev \
    liblzo2-dev \
    libpng-dev \
    libsndfile1-dev \
    ocl-icd-opencl-dev \
    opencl-headers \
    qmake6 \
    qt6-base-dev \
    qt6-base-dev-tools \
    qt6-declarative-dev \
    qt6-multimedia-dev \
    qt6-qpa-plugins \
    qt6-tools-dev \
    sudo \
    wget \
    && rm -rf /var/lib/apt/lists/*

ARG VERSION="2.34"
RUN useradd -ms /bin/bash user
RUN mkdir /home/user/mandelbulber2
WORKDIR /home/user/mandelbulber2
RUN export DOWNLOAD_URL=$(curl https://api.github.com/repos/buddhi1980/mandelbulber2/releases | jq -r -c ".[] | select (.[\"tag_name\"] != \"continuous\") | select( .[\"tag_name\"] | contains(\"${VERSION}\")) | .assets[] | select (.content_type | contains(\"application/gzip\")) | .[\"browser_download_url\"]"); echo ${DOWNLOAD_URL}; wget -O /tmp/mandelbulber.tar.gz ${DOWNLOAD_URL}
RUN tar -xf /tmp/*.tar.gz -C .
# Release tarballs still ship makefiles/ (git tree uses qmake/). Prefer qmake6.
RUN cd mandelbulber2*/makefiles && qmake6 mandelbulber-opencl.pro && make -j"$(nproc)" all
RUN cd mandelbulber2* && ./install
ENTRYPOINT ["mandelbulber2"]
