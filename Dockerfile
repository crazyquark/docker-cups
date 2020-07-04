# Based on https://blog.project-insanity.org/2020/05/19/cups-airprint-server-with-legacy-printer-driver-support/
FROM archlinux
LABEL maintainer="cristian.sandu@gmail.com"

ENV USER_PID=1000

# Upgrade
RUN pacman --noconfirm -Suy

# Basics
RUN pacman --noconfirm -S fakeroot git gcc cmake make ghostscript cups supervisor

# Supervisor config
RUN mkdir -p /var/log/supervisord/
ADD cups.conf /etc/supervisor.d/

# Can't run makepkg as root
RUN useradd -r -u ${USER_PID} archuser && \
    mkdir -p /home/archuser && \
    chown -R archuser /home/archuser

USER archuser
WORKDIR /home/appuser

# Build Canon drivers
RUN git clone https://aur.archlinux.org/cnijfilter2-bin.git && cd cnijfilter2-bin && makepkg

# Install as root
USER root
RUN cd cnijfilter2-bin && pacman --noconfirm -U cnijfilter2-*.pkg.tar.xz && cd .. && rm -rf cd cnijfilter2-bin

# Bind to 0.0.0.0
RUN sed -i s/localhost:631/0.0.0.0:631/g /etc/cups/cupsd.conf

CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisor.d/cups.conf" ]
