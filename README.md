# arkiweb-docker-image

[Arkiweb](https://github.com/ARPA-SIMC/arkiweb/) recently became
incompatible with the [arkimet](https://github.com/ARPA-SIMC/arkimet/)
C++ API's. This package allows to create a docker container including
a web server, arkiweb and an arkiweb-compatible version of arkimet, to
be run within a host having a newer arkimet version, replacing arkiweb
on the host. This allows to keep arkiweb running while keeping arkimet
updated to the latest version.

The web server in the host talks with the web server in the container
through apache `mod_proxy` module, while the arkiweb in the container
interacts with the arkimet datasets in the host through the host
arkimet server http interface.

For more detailed instruction on how to build and start the docker
image and configure the system, see the [HOWTO](HOWTO_it.md) in
Italian.
