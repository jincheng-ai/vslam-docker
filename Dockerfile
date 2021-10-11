FROM nvidia/cudagl:10.2-devel-ubuntu18.04
MAINTAINER jincheng <jincheng.jcs@gmail.com>

ENV DEBIAN_FRONTEND=noninteractive
ENV CERES_VERSION="1.14.0"
ENV OPENCV_VERSION="4.5.3"
ENV JOBS_NUM="4"
ENV  CUDA_ARCH_BIN="7.2"
ENV ROS_DISTRO="melodic"

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

# CUDA
# RUN apt-get update && apt-get remove -y x264 libx264-dev
# RUN apt-get install --assume-yes apt-utils
# RUN apt-get update && apt-get upgrade -y && apt-get install -y sudo clang-format wget apt-utils libcudnn7 libcudnn7-dev

# Set apt
RUN apt-get update -q && \
    apt-get upgrade -yq
RUN apt-get install -yq locales wget curl sudo cmake git build-essential vim lsb-release bash-completion clang-format \
    pkg-config yasm software-properties-common && \
    locale-gen en_US.UTF-8
RUN mkdir /installer &&	cd /installer && \
	git clone https://github.com/ceres-solver/ceres-solver.git
RUN cd /installer && \
	git clone https://github.com/stevenlovegrove/Pangolin.git
# Fetch OpenCV
RUN cd /opt && wget https://github.com/opencv/opencv/archive/refs/tags/${OPENCV_VERSION}.tar.gz && \
    tar -xf  ${OPENCV_VERSION}.tar.gz
RUN cd /opt && wget https://github.com/opencv/opencv_contrib/archive/refs/tags/${OPENCV_VERSION}.tar.gz &&\
    mkdir opencv_contrib && tar -xf 4.5.3.tar.gz -C opencv_contrib --strip-components 1

RUN apt-get install --assume-yes apt-utils
RUN sh -c 'echo "deb http://packages.ros.org/ros/ubuntu bionic main" > /etc/apt/sources.list.d/ros-latest.list'
RUN curl -k https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | sudo apt-key add -
RUN apt-get update -q

RUN apt-get remove -y x264 libx264-dev
RUN apt-get install -yq \
    # for cuda
    libcudnn7 libcudnn7-dev \
    # for ROS Melodic
    ros-${ROS_DISTRO}-desktop-full python-rosdep ros-${ROS_DISTRO}-tf-conversions ros-${ROS_DISTRO}-rviz \
    # for SLAM Developer
    libboost-all-dev  libgoogle-glog-dev libeigen3-dev libsuitesparse-dev libgl1-mesa-dev libglew-dev libxkbcommon-x11-dev \
    # for OpenGL
    libgl1-mesa-dev libglu1-mesa-dev freeglut3-dev libxi-dev \
    # for OpenCV
    checkinstall gfortran libjpeg8-dev libtiff5-dev libavcodec-dev libavformat-dev \
    libswscale-dev libdc1394-22-dev libxine2-dev libv4l-dev \
    qt5-default libgtk2.0-dev libtbb-dev libatlas-base-dev \
    libfaac-dev libmp3lame-dev libtheora-dev libvorbis-dev libxvidcore-dev libopencore-amrnb-dev \
    libopencore-amrwb-dev x264 v4l-utils libprotobuf-dev protobuf-compiler libgoogle-glog-dev \
    libgflags-dev libgphoto2-dev libeigen3-dev libhdf5-dev doxygen \
    python-dev python-pip python3-dev python3-pip \
    # for ffmpeg
    ffmpeg && \    
    rm -rf /var/lib/apt/lists/*

# ceres
RUN cd /installer && \
	cd ceres-solver && git checkout tags/${CERES_VERSION} && \
	mkdir build && cd build && \
	cmake .. && make -j"$(nproc)" install && \
	cd /installer && \
	cd Pangolin && mkdir build && cd build && \
	cmake .. && make -j"$(nproc)" install && \
	rm -rf /installer/*

# OpenCV
# Get OpenCV dependencies
RUN pip2 install -U pip numpy -i https://opentuna.cn/pypi/web/simple &&\
    pip3 install -U pip numpy -i https://opentuna.cn/pypi/web/simple &&\
    pip install numpy scipy matplotlib scikit-image scikit-learn ipython -i https://opentuna.cn/pypi/web/simple
RUN ls /opt/opencv_contrib/modules
RUN cd /opt/opencv-${OPENCV_VERSION} && mkdir release && cd release && \
    cmake -G "Unix Makefiles" -DENABLE_PRECOMPILED_HEADERS=OFF -DCMAKE_CXX_COMPILER=/usr/bin/g++ \
    CMAKE_C_COMPILER=/usr/bin/gcc -DCMAKE_BUILD_TYPE=RELEASE -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DWITH_TBB=ON -DBUILD_NEW_PYTHON_SUPPORT=ON -DWITH_V4L=ON -DINSTALL_C_EXAMPLES=OFF \
    -DINSTALL_PYTHON_EXAMPLES=ON -DBUILD_EXAMPLES=OFF -DWITH_QT=ON -DWITH_OPENGL=ON \
    -DWITH_FFMPEG=ON \
    -DWITH_CUDA=ON -DWITH_CUDNN=ON -DCUDA_ARCH_BIN=${CUDA_ARCH_BIN} -DOPENCV_DNN_CUDA=ON -DCUDA_GENERATION=Auto -DOPENCV_EXTRA_MODULES_PATH=/opt/opencv_contrib/modules \
    .. &&\
    make -j"$(nproc)"  && \
    make install && \
    ldconfig &&\
    cd /opt/opencv/release && make clean

RUN useradd -m -d /home/ubuntu ubuntu -p `perl -e 'print crypt("ubuntu", "salt"),"\n"'` && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ubuntu
WORKDIR /home/ubuntu
ENV HOME=/home/ubuntu \
    CATKIN_SHELL=bash

RUN rosdep init
RUN rosdep update
RUN mkdir -p ~/catkin_ws/src \
    && /bin/bash -c '. /opt/ros/melodic/setup.bash; catkin_init_workspace $HOME/catkin_ws/src' \
    && /bin/bash -c '. /opt/ros/melodic/setup.bash; cd $HOME/catkin_ws; catkin_make'
RUN echo 'source /opt/ros/melodic/setup.bash' >> ~/.bashrc \
    && echo 'source ~/catkin_ws/devel/setup.bash' >> ~/.bashrc
COPY ./ros_entrypoint.sh /

ENTRYPOINT ["/ros_entrypoint.sh"]
