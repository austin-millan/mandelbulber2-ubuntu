# FROM ubuntu:18.04 as build
FROM ubuntu:18.04 as build
LABEL maintainer="austin.millan@protonmail.com"
LABEL org.label-schema.name="docker-mandelbulber2"
LABEL org.label-schema.url="https://www.mandelbulber.com/"
LABEL org.label-schema.vcs-url="https://github.com/buddhi1980/mandelbulber2"
LABEL org.label-schema.description="Run Mandelbulber2 in a docker container."
LABEL org.label-schema.docker.cmd='docker run -e USER_UID=${id} -it --net=host --env="DISPLAY" -v $HOME/.mandelbulber:/root/.mandelbulber:rw -v $HOME/.Xauthority:/root/.Xauthority:rw --entrypoint="mandelbulber2" registry.gitlab.com/mandelbulber/mandelbulber2-ubuntu:2.2'
LABEL org.label-schema.docker.cmd.help="docker run -e USER_UID=${id} -it --entrypoint="mandelbulber2" registry.gitlab.com/mandelbulber/mandelbulber2-ubuntu:2.25 --help"
LABEL org.label-schema.docker.build='docker build --build-arg VERSION=2.25 -t austin-millan/mandelbulber2:local .'

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
    desktop-file-utils \
    qml \ 
    qtdeclarative5-dev \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update
ARG VERSION="2.25"
RUN useradd -ms /bin/bash user
RUN mkdir /home/user/mandelbulber2
WORKDIR /home/user/mandelbulber2
RUN export DOWNLOAD_URL=$(curl https://api.github.com/repos/buddhi1980/mandelbulber2/releases | jq -r -c ".[] | select (.[\"tag_name\"] != \"continuous\") | select( .[\"tag_name\"] | contains(\"${VERSION}\")) | .assets[] | select (.content_type | contains(\"application/gzip\")) | .[\"browser_download_url\"]"); echo ${DOWNLOAD_URL}; wget -O /tmp/mandelbulber.tar.gz ${DOWNLOAD_URL}
RUN tar -xf /tmp/*.tar.gz -C .
RUN cd mandelbulber2*/makefiles && qmake mandelbulber-opencl.pro && make all > /dev/null
# RUN cd mandelbulber2*/makefiles && qmake mandelbulber-opencl.pro
RUN cd mandelbulber2* && ./install
ENTRYPOINT ["mandelbulber2"]
