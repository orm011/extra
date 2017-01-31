FROM ubuntu:trusty

RUN apt-get update
RUN echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list
RUN apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116
RUN apt-get update
RUN apt-get install -y ros-indigo-desktop-full
RUN apt-get install -y python-rosinstall

# Replace 1000 with your user / group id
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer

USER developer
ENV HOME /home/developer
RUN sudo rosdep init
RUN rosdep update
RUN echo "alias indigo='source /opt/ros/indigo/setup.bash'" >> ~/.bashrc

# Install vnc, xvfb in order to create a 'fake' display and firefox
RUN     sudo apt-get install -y x11vnc xvfb
RUN     mkdir ~/.vnc

# Setup a vnc password
RUN     x11vnc -storepasswd 1234 ~/.vnc/passwd

# now install the python side of tools
RUN sudo apt-get install wget
RUN cd /tmp/ && wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh

# conda
WORKDIR /home/developer
RUN bash /tmp/Miniconda3-latest-Linux-x86_64.sh -b
RUN echo 'getpath() {  echo $PATH ; }' >> ~/.bashrc
RUN echo "alias addconda='export PATH=/home/developer/miniconda3/bin/:$(getpath)'" >> ~/.bashrc

# emacs
RUN sudo apt-get install -y emacs
ENV EDITOR /usr/bin/emacs

# prepare env for BotDB. assumes you have mounted the ssh keys.
RUN bash -c 'addconda && conda config --add channels menpo'

WORKDIR /home/developer

# requires mounting .ssh folder, or you can do it from your host.
# RUN git clone --recursive git@github.com:spillai/BotDB