FROM centos:7

COPY build.sh /build.sh
RUN /bin/bash /build.sh
CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
EXPOSE 80
