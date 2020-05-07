FROM centos:7

COPY build.sh /build.sh
RUN /bin/bash /build.sh
COPY match-alias.conf /etc/arkimet/match-alias.conf
CMD ["/usr/bin/bash", "-c", "echo 172.17.0.1 lami.hpc.cineca.it >> /etc/hosts; rm -f /run/httpd/httpd.pid; /usr/sbin/httpd -D FOREGROUND"]
EXPOSE 80
