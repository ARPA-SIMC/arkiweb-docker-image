FROM centos:7

COPY build.sh /build.sh
RUN /bin/bash /build.sh
CMD ["/usr/bin/bash", "-c", "rm -f /run/httpd/httpd.pid; /usr/sbin/httpd -D FOREGROUND"]
EXPOSE 80
