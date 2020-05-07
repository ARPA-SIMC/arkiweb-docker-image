FROM centos:7

COPY build.sh /build.sh
RUN /bin/bash /build.sh
COPY match-alias.conf /etc/arkimet/match-alias.conf
CMD ["/bin/bash", "-c", "echo 172.17.0.1 lami.hpc.cineca.it >> /etc/hosts && /usr/sbin/httpd -D FOREGROUND"]
EXPOSE 80
