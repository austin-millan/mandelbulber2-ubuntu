FROM ubuntu:18.04 as build
LABEL org.label-schema.name="docker-mandelbulber2"
LABEL maintainer="austin.millan@protonmail.com"
LABEL org.label-schema.url="https://www.mandelbulber.com/"
LABEL org.label-schema.vcs-url="https://github.com/buddhi1980/mandelbulber2"
LABEL org.label-schema.description="Run Mandelbulber2 in a docker container."

RUN apt-get update && apt-get install --no-install-recommends -y \
    curl \
    wget \
    qt5-default \
    g++ \
    libqt5gui5 \
    qt5-default \
    qttools5-dev \
    qttools5-dev-tools \
    libgomp1 \
    qtmultimedia5-dev \
    libqt5multimediawidgets5 \
    libqt5multimedia5-plugins \
    libqt5multimedia5 \
    libgsl-dev \
    libpng-dev \
    liblzo2-dev \
    ocl-icd-opencl-dev \
    sudo \
    opencl-headers \
    jq \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN useradd -ms /bin/bash user
RUN mkdir /home/user/mandelbulber2
WORKDIR /home/user/mandelbulber2
ARG VERSION="2.24"
ENV VERSION="2.24"
RUN echo $VERSION; export DOWNLOAD_URL=$(curl https://api.github.com/repos/buddhi1980/mandelbulber2/releases | jq -r -c ".[] | select (.[\"tag_name\"] != \"continuous\") | select( .[\"tag_name\"] | contains(\"${VERSION}\")) | .assets[] | select (.content_type | contains(\"application/gzip\")) | .[\"browser_download_url\"]"); echo ${DOWNLOAD_URL}; wget -O /tmp/mandelbulber.tar.gz ${DOWNLOAD_URL}
RUN tar -xf /tmp/*.tar.gz -C .
RUN cd mandelbulber2*/makefiles && qmake mandelbulber-opencl.pro && make all
RUN cd mandelbulber2* && ./install
ENTRYPOINT ["mandelbulber2"]
#CMD ["mandelbulber2"]
