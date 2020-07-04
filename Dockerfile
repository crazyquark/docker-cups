# Based on https://blog.project-insanity.org/2020/05/19/cups-airprint-server-with-legacy-printer-driver-support/
FROM archlinux
LABEL maintainer="cristian.sandu@gmail.com"

ENV USER_PID=1000

ENV CUPSADMIN=admin
ENV CUPSPASSWORD=password

# Upgrade
RUN pacman --noconfirm -Suy

# Basics
RUN pacman --noconfirm -S fakeroot git gcc cmake make ghostscript cups avahi supervisor

# Supervisor config
RUN mkdir -p /var/log/supervisord/
ADD config/supervisord.conf /etc/

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

# Create cups admin user
RUN useradd -r -U $CUPSADMIN
RUN echo $CUPSADMIN:$CUPSPASSWORD | chpasswd

# Configure cups
RUN sed -i 's/Listen localhost:631/Listen 0.0.0.0:631/' /etc/cups/cupsd.conf && \
	sed -i 's/Browsing Off/Browsing On/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/>/<Location \/>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin>/<Location \/admin>\n  Allow All\n  Require user @SYSTEM/' /etc/cups/cupsd.conf && \
	sed -i 's/<Location \/admin\/conf>/<Location \/admin\/conf>\n  Allow All/' /etc/cups/cupsd.conf && \
	sed -i 's/.*enable\-dbus=.*/enable\-dbus\=no/' /etc/avahi/avahi-daemon.conf && \
	echo "ServerAlias *" >> /etc/cups/cupsd.conf && \
	echo "DefaultEncryption Never" >> /etc/cups/cupsd.conf

CMD [ "/usr/bin/supervisord", "-c", "/etc/supervisor.d/supervisord.conf" ]
