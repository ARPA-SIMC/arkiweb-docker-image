## Arkiweb in un docker container ##

Arkiweb al momento non è più compatibile con le ultime versioni delle
API C++ di arkimet e non si sa se e quando lo sarà di nuovo.

Questo pacchetto consente, almeno per un po' di tempo, di garantire la
sopravvivenza di arkiweb in questi tempi difficili, creando un
ambiente arkimet che sia arkiweb-compatibile, finalizzato al solo
arkiweb, da eseguire in un container in un host dotato di un arkimet
recente non arkiweb-compatibile e di web server configurato.

Questa guida pratica è basata sull'installazione sul servar lami al
Cineca (CentOS 7). Anche il container è basato su CentOS 7 ma in
generale non è necessario che le distribuzioni host e container
coincidano.

### Creazione del docker container ###

Non avendo avuto il tempo di indagare su come abilitare un altro
utente, il container è stato creato ed eseguito da utente root.

```
yum install docker
git clone https://github.com/ARPA-SIMC/arkiweb-docker-image
cd arkiweb-docker-image
```

È stato modificato Dockerfile nella riga:

```
CMD ["/bin/bash", "-c", "echo 172.17.0.1 lami.hpc.cineca.it >> /etc/hosts && /usr/sbin/httpd -D FOREGROUND"]
```

per permettere al container di parlare a sé stesso usando
l'hostname. Si dovrà trovare una maniera migliore per farlo o evitare
l'esigenza di usare il fqdn dentro il container.

Ricostruisco ora l'immagine (per non chiari motivi non funzionava il
pull dell'imagine dal docker-hub, ma comunque dobbiamo rigenerarla ad
hoc):

```
docker build --no-cache -t arkiweb:3 .
```

A questo punto la mia immagine è visibile con `docker image ls -a`.

### Configurazione del docker container ###

Procediamo con la creazione delle cartelle locali destinate a
contenere i file di configurazione specifici per la nostra
installazione e con il loro popolamento. Il risultato è:

```
[~]# ls -lR arkiweb-docker
arkiweb-docker:
total 4
drwxrwxr-x 2 root root  51 Feb 12 08:00 config
drwxrwxr-x 2 root root  25 Feb 11 17:41 httpd

arkiweb-docker/config:
total 32
-rw-rw-r-- 1 root   root   25755 Feb 11 14:56 arkiweb.config
-rw------- 2 apache apache  1200 Oct 15  2018 arkiweb.passwords

arkiweb-docker/httpd:
total 4
-rw-rw-r-- 1 root root 803 Feb 11 14:56 arkiweb.conf
```

`arkiweb.config` è il file di configurazione dei dataset
originariamente destinato all'arkiweb dell'host, ora fuori uso, nel
caso nostro punta al server arkimet con il nome completo:

```
server = http://lami.hpc.cineca.it:8090
```

`arkiweb.passwords` è il file di autenticazione del web server
dell'host (potendo ho fatto un hard link). `arkiweb.conf` è il file di
configurazione di apache per arkiweb, modificato rispetto
all'originale nell'abilitazione dell'autenticazione e nei path dei
file di configurazione dei dataset e di autenticazione.

A questo punto sono pronto per far partire il container dall'immagine,
che si chiama nel nostro caso `arkiweb:3`; lo faccio con questo
comando:

```
docker run --name arkiweb -p 8080:80 \
 -v $HOME/arkiweb-docker/config:/mnt/arkiweb \
 -v $HOME/arkiweb-docker/httpd:/etc/httpd/conf.d arkiweb:3
```

poi lo interrompo con ctrl-c. È una maniera strana di procedere, ma
così facendo dall'immagine `arkiweb:3` viene creato un container
chiamato semplicemente `arkiweb`, già configurato coi ridirezionamenti
delle porte e i montaggi delle cartelle come volumi. A questo punto il
mio container `arkiweb` compare in `docker container ls -a`.

### Avvio del docker container ###

Per farlo partire sul serio e far sì che si avvii automaticamente ai
riavvii successivi, creo un file
`/usr/lib/systemd/system/arkiweb.service` sulla base dell'esempio
contenuto in (service/arkiweb-docker.service)[arkiweb-docker.service]
e successivamente abilito permanentemente il relativo servizio,
assieme a docker stesso:

```
systemctl enable docker.service
systemctl enable arkiweb.service
```

li avvio a mano per la sessione corrente

```
systemctl start docker.service
systemctl start arkiweb.service
```
e con questo il container dovrebbe essere a posto.

A container avviato (assumendo il nome `arkiweb`), posso "entrarci dentro" con:

```
docker exec -ti arkiweb /bin/bash
```

### Configurazione del web server dell'host ###

Assumendo che l'host abbia un web server apache già correttamente
configurato e originariamente pensato per servire arkiweb, sostituisco
il file `/etc/httpd/conf.d/arkiweb.conf` originale con un file di
configurazione per `mod_proxy` di apache che rimanda al web server del
container:

```
ProxyPass "/services/arkiweb" "http://localhost:8080/services/arkiweb"
ProxyPassReverse "/services/arkiweb" "http://localhost:8080/services/arkiweb"
ProxyPass "/arkiwebjs" "http://localhost:8080/arkiwebjs"
ProxyPassReverse "/arkiwebjs" "http://localhost:8080/arkiwebjs"
ProxyPass "/arkiweb" "http://localhost:8080/arkiweb"
ProxyPassReverse "/arkiweb" "http://localhost:8080/arkiweb"
```

e chiaramente riavvio il server con `systemctl restart httpd.service`.

A questo punto ho di nuovo arkiweb.

### Utilizzo di Singularity ###

Data la scarsa esperienza con docker tutto si può replicare in maniera
relativamente facile con un container singularity, che è più facile da
gestire e non richiede un demone. È stato quindi creato un file di
definizione singularity, con nome `Singularity`, che riproduce quanto
fatto con docker.

Per creare il container eseguo:

```
singularity build --sandbox arkiweb-image Singularity
```

questo crea un container in un filesystem modificabile, se ometto
`--sandbox` mi crea invece un container statico portatile in un
singolo file compresso.

Per avviare un'istanza permanente, utilizzando gli stessi file di
configurazione creati per docker, eseguo:

```
singularity instance start --writable-tmpfs \
 -B $HOME/arkiweb-docker/config:/mnt/arkiweb \
 -B $HOME/arkiweb-docker/httpd:/etc/httpd/conf.d \
 --net --network-args "portmap=8080:80/tcp" \
 arkiweb-image arkiweb
```

l'istanza si chiama `arkiweb`, i comandi utili, con ovvio significato,
sono:

```
singularity instance list
singularity shell instance://arkiweb
singularity instance stop arkiweb
```

La configurazione della rete è molto simile quella di docker perché
anche singularity, a partire da una versone 3.qualcosa, utilizza gli
stessi plugin di rete "CNI" usati da docker.

Se voglio rendere l'istanza permanente all'avvio del sistema, procedo,
similmente al caso docker, installando il file
(service/arkiweb-singularity.service) come servizio systemctl in
`/usr/lib/systemd/system/arkiweb-singularity.service` e il relativo
file di configurazione (service/arkiweb-singularity) in
`/etc/sysconfig/arkiweb-singularity`.
