# Based on https://blog.project-insanity.org/2020/05/19/cups-airprint-server-with-legacy-printer-driver-support/
FROM archlinux
LABEL maintainer="cristian.sandu@gmail.com"

ENV USER_PID=1000
ENV LP_GID=7

ENV ROOTPASSWORD=password

# Upgrade
RUN pacman --noconfirm -Suy

# Basics
RUN pacman --noconfirm -S fakeroot git gcc cmake make ghostscript cups gnu-free-fonts avahi supervisor automake autoconf

# Supervisor config
RUN mkdir -p /var/log/supervisord/
ADD config/supervisord.conf /etc/

# Can't run makepkg as root
RUN useradd -r -u ${USER_PID} archuser && \
    mkdir -p /home/archuser && \
    chown -R archuser /home/archuser

USER archuser
WORKDIR /home/archuser

# Build Canon drivers
# Source: https://aur.archlinux.org/packages/cnijfilter2/
RUN mkdir cnijfilter2
ADD cnijfilter2/PKGBUILD /home/archuser/cnijfilter2/PKGBUILD
RUN cd cnijfilter2 && makepkg

# Install as root
USER root
RUN cd cnijfilter2 && pacman --noconfirm -U cnijfilter2*.pkg.tar.xz

# Change 
RUN groupmod -g ${LP_GID} lp
RUN echo root:${ROOTPASSWORD} | chpasswd

# Configure cups
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
	sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/.*enable\-dbus=.*/enable\-dbus\=no/' /etc/avahi/avahi-daemon.conf && \
	echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
	echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf

CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisord.conf" ]
