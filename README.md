# stubby-docker

Debian based docker image with stubby installed. 

## Getting Started

These instructions will get you a copy of the project up and running on your local machine. 

### Prerequisites

Things you need to install the software

```
Docker
```

### Start It

Replace Docker-HostIP with the IP of your Docker-Host

Replace the 1st Port if you want to use another on your Docker-Host

```
sudo docker run -d --name stubby -p Docker-HostIP:8053:8053/udp --restart unless-stopped space2walker/stubby-docker
```

### Pi-Hole Setup

If you want to use stubby in compination with pi-hole 

```
sudo docker run -d --name stubby -p Docker-HostIP:8053:8053/udp --restart unless-stopped space2walker/stubby-docker
```

start dignic/pi-hole 

```
sudo docker run -d --name pihole \
-p Docker-HostIP:53:53/tcp \
-p Docker-HostIP:53:53/udp \
-p Docker-HostIP:80:80 \
-v "~/pihole/pihole/:/etc/pihole/" \
-v "~/pihole/dnsmasq.d/:/etc/dnsmasq.d/" \
-e ServerIP="Docker-HostIP" \
-e Ipv6="false"\
--restart unless-stopped \
diginc/pi-hole:latest
```

for the dignic/pi-pihole setup take a look at [dignic/pi-pihole](https://github.com/diginc/docker-pi-hole)

after the initial setup of pi-hole you have to do the following changes

create a new configfile /etc/dnsmasq.d/02-stubby.conf and enter the Stubby address:

```
server=Docker-HostIP#8053
```

Adaptation to the Pi-hole so that the servers are not duplicated or incorrectly configured:
* delete server= from /etc/dnsmasq.d/01-pihole.conf.
* delete PIHOLE_DNS_1 from /etc/pihole/setupVars.conf.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* [getdns](https://github.com/getdnsapi/stubby)
* [Matthew Vance](https://github.com/MatthewVance/stubby-docker)
* [Docker](https://www.docker.com/)