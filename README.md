# Docker-Nagios

Docker image for Nagios

Build Status: [![Build Status](https://travis-ci.org/joostkuif/Docker-Nagios.svg?branch=master)](https://travis-ci.org/joostkuif/Docker-Nagios)

Nagios Core 4.4.5 running on Ubuntu 16.04 LTS with NagiosGraph & NRPE & Oracle client & SSL & LDAP Auth

### Configurations
Nagios Configuration lives in /opt/nagios/etc
NagiosGraph configuration lives in /opt/nagiosgraph/etc

### Install

```sh
docker pull jkuif/nagios:latest
```

### Running

Run with the external Nagios configuration & log data with the following:

```sh
docker run --name nagios4  \
  -v /path-to-nagios/var:/opt/nagios/var \
  -v /path-to-nagios/etc:/opt/nagios/etc \
  -v /path-to-nagios/certs:/opt/nagios/certs \
  -v /path-to-apache2-config:/opt/nagios/apache2 \
  -v /path-to-apache-log-dir:/var/log/apache2 \
  -v /path-to-custom-plugins:/opt/Custom-Nagios-Plugins \
  -v /path-to-nagiosgraph-var:/opt/nagiosgraph/var \
  -v /path-to-nagiosgraph-etc:/opt/nagiosgraph/etc \
  -p 0.0.0.0:8080:80 -p 0.0.0.0:443:443 jkuif/nagios:latest
```

Note: The path for the custom plugins will be /opt/Custom-Nagios-Plugins, you will need to reference this directory in your configuration scripts.

There are a number of environment variables that you can use to adjust the behaviour of the container:

| Environamne Variable | Description |
|--------|--------|
| MAIL_RELAY_HOST | Set Postfix relayhost |
| MAIL_INET_PROTOCOLS | set the inet_protocols in postfix |
| NAGIOS_FQDN | set the server Fully Qualified Domain Name in postfix |
| NAGIOS_TIMEZONE | set the timezone of the server |

For best results your Nagios image should have access to both IPv4 & IPv6 networks 


### Extra Plugins

* Nagios nrpe [<http://exchange.nagios.org/directory/Addons/Monitoring-Agents/NRPE--2D-Nagios-Remote-Plugin-Executor/details>]
* Nagiosgraph [<http://exchange.nagios.org/directory/Addons/Graphing-and-Trending/nagiosgraph/details>]

