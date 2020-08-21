FROM ubuntu:18.04 as build

RUN apt-get update -y
RUN apt-get install -y \
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
    opencl-headers
RUN useradd -ms /bin/bash user
RUN mkdir /home/user/mandelbulber2
WORKDIR /home/user/mandelbulber2
RUN curl -s https://api.github.com/repos/buddhi1980/mandelbulber2/releases/latest \
| grep "browser_download_url.*.tar.gz" \
| cut -d : -f 2,3 \
| tr -d \" \
| wget -O /tmp/mandelbulber.tar.gz -qi -

RUN tar -xf /tmp/*.tar.gz -C .

RUN cd mandelbulber2*/makefiles && qmake mandelbulber-opencl.pro && make all

CMD ["mandelbulber2"]