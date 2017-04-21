FROM dock0/pkgforge
RUN pacman -S --needed --noconfirm libxslt docbook-xsl gnome-doc-utils
