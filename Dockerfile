# Based on https://blog.project-insanity.org/2020/05/19/cups-airprint-server-with-legacy-printer-driver-support/
FROM archlinux
LABEL maintainer="cristian.sandu@gmail.com"

ENV USER_PID=1000

# Upgrade
RUN pacman --noconfirm -Suy

# Basics
RUN pacman --noconfirm -S fakeroot git gcc cmake make sudo go cups supervisor

# Supervisor config
ADD supervisor.conf /etc/

# Can't run makepkg as root
RUN useradd -r -u ${USER_PID} archuser && \
    mkdir -p /home/archuser && \
    chown -R archuser /home/archuser

USER archuser
WORKDIR /home/appuser

# Yay AUR helper
RUN git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si && cd .. && rm -rf yay

# Canon drivers
RUN yay --noconfirm -S cnijfilter2-bin
