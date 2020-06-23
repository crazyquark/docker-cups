# Based on https://blog.project-insanity.org/2020/05/19/cups-airprint-server-with-legacy-printer-driver-support/
FROM archlinux
LABEL maintainer="cristian.sandu@gmail.com"

# Upgrade
RUN pacman --noconfirm -Suy

# Basics
RUN pacman -S fakeroot git gcc cmake make cups

# Yay AUR helper
RUN git clone https://aur.archlinux.org/yay.git && cd yay && makepkg -si && cd .. && rm -rf yay

# Canon drivers
RUN yay --noconfirm -S cnijfilter2-bin