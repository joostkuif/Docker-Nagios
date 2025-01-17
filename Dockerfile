FROM ubuntu:16.04
MAINTAINER Joost Kuif <joost.kuif@gmail.com>

ENV NAGIOS_HOME            /opt/nagios
ENV NAGIOS_USER            nagios
ENV NAGIOS_GROUP           nagios
ENV NAGIOS_CMDUSER         nagios
ENV NAGIOS_CMDGROUP        nagios
ENV NAGIOS_FQDN            nagios.nexus-nederland.nl
ENV NAGIOSADMIN_USER       nagiosadmin
ENV NAGIOSADMIN_PASS       nagios
ENV APACHE_RUN_USER        nagios
ENV APACHE_RUN_GROUP       nagios
ENV NAGIOS_TIMEZONE        Europe/Amsterdam
ENV DEBIAN_FRONTEND        noninteractive
ENV NG_NAGIOS_CONFIG_FILE  ${NAGIOS_HOME}/etc/nagios.cfg
ENV NG_CGI_DIR             ${NAGIOS_HOME}/sbin
ENV NG_WWW_DIR             ${NAGIOS_HOME}/share/nagiosgraph
ENV NG_CGI_URL             /cgi-bin
ENV NAGIOS_BRANCH          nagios-4.4.5
ENV NAGIOS_PLUGINS_BRANCH  release-2.2.1
ENV NRPE_BRANCH            nrpe-3.2.1

RUN echo postfix postfix/main_mailer_type string "'Internet Site'" | debconf-set-selections  && \
    echo postfix postfix/mynetworks string "127.0.0.0/8" | debconf-set-selections            && \
    echo postfix postfix/mailname string ${NAGIOS_FQDN} | debconf-set-selections

#haal sources uit NL (bit.nl)
RUN echo "###### Ubuntu Main Repos" > /etc/apt/sources.list && \
    echo "deb http://nl.archive.ubuntu.com/ubuntu/ xenial main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb-src http://nl.archive.ubuntu.com/ubuntu/ xenial main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "###### Ubuntu Update Repos" >> /etc/apt/sources.list && \
    echo "deb http://nl.archive.ubuntu.com/ubuntu/ xenial-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://nl.archive.ubuntu.com/ubuntu/ xenial-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb-src http://nl.archive.ubuntu.com/ubuntu/ xenial-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb-src http://nl.archive.ubuntu.com/ubuntu/ xenial-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    apt-get update

RUN apt-get install -y apt-utils

RUN apt-get install -y    \
        apache2                             \
        apache2-utils                       \
        autoconf                            \
        automake                            \
        bc                                  \
        bsd-mailx                           \
        build-essential                     \
        dnsutils                            \
        fping                               \
        gettext                             \
        git                                 \
        gperf                               \
        iputils-ping                        \
        jq                                  \
        libapache2-mod-php                  \
        libcache-memcached-perl             \
        libcgi-pm-perl                      \
        libdbd-mysql-perl                   \
        libdbi-dev                          \
        libdbi-perl                         \
        libfreeradius-client-dev            \
        libgd2-xpm-dev                      \
        libgd-gd2-perl                      \
        libjson-perl                        \
        libldap2-dev                        \
        libmysqlclient-dev                  \
        libnagios-object-perl               \
        libnagios-plugin-perl               \
        libnet-snmp-perl                    \
        libnet-snmp-perl                    \
        libnet-tftp-perl                    \
        libnet-xmpp-perl                    \
        libpq-dev                           \
        libredis-perl                       \
        librrds-perl                        \
        libssl-dev                          \
        libswitch-perl                      \
        libwww-perl                         \
        m4                                  \
        netcat                              \
        parallel                            \
        php-cli                             \
        php-gd                              \
        postfix                             \
        python-pip                          \
        rsyslog                             \
        runit                               \
        smbclient                           \
        snmp                                \
        snmpd                               \
        snmp-mibs-downloader                \
        unzip                               \
        python                              \
        lsb-release gnupg libc6 libyaml-perl alien libaio1 vim net-tools dos2unix

RUN ( egrep -i "^${NAGIOS_GROUP}"    /etc/group || groupadd $NAGIOS_GROUP    )                         && \
    ( egrep -i "^${NAGIOS_CMDGROUP}" /etc/group || groupadd $NAGIOS_CMDGROUP )
RUN ( id -u $NAGIOS_USER    || useradd --system -d $NAGIOS_HOME -g $NAGIOS_GROUP    $NAGIOS_USER    )  && \
    ( id -u $NAGIOS_CMDUSER || useradd --system -d $NAGIOS_HOME -g $NAGIOS_CMDGROUP $NAGIOS_CMDUSER )

#RUN cd /tmp                                           && \
#    git clone https://github.com/multiplay/qstat.git  && \
#    cd qstat                                          && \
#    ./autogen.sh                                      && \
#    ./configure                                       && \
#    make                                              && \
#    make install                                      && \
#    make clean                                        && \
#    cd /tmp && rm -Rf qstat

RUN cd /tmp                                                                          && \
    git clone https://github.com/NagiosEnterprises/nagioscore.git -b $NAGIOS_BRANCH  && \
    cd nagioscore                                                                    && \
    ./configure                                  \
        --prefix=${NAGIOS_HOME}                  \
        --exec-prefix=${NAGIOS_HOME}             \
        --enable-event-broker                    \
        --with-command-user=${NAGIOS_CMDUSER}    \
        --with-command-group=${NAGIOS_CMDGROUP}  \
        --with-nagios-user=${NAGIOS_USER}        \
        --with-nagios-group=${NAGIOS_GROUP}      \
                                                                                     && \
    make all                                                                         && \
    make install                                                                     && \
    make install-config                                                              && \
    make install-commandmode                                                         && \
    make install-webconf                                                             && \
    make clean                                                                       && \
    cd /tmp && rm -Rf nagioscore

RUN cd /tmp                                                                                   && \
    git clone https://github.com/nagios-plugins/nagios-plugins.git -b $NAGIOS_PLUGINS_BRANCH  && \
    cd nagios-plugins                                                                         && \
    ./tools/setup                                                                             && \
    ./configure                                                 \
        --prefix=${NAGIOS_HOME}                                 \
        --with-ipv6                                             \
        --with-ping6-command="/bin/ping6 -n -U -W %d -c %d %s"  \
                                                                                              && \
    make                                                                                      && \
    make install                                                                              && \
    make clean                                                                                && \
    mkdir -p /usr/lib/nagios/plugins                                                          && \
    ln -sf ${NAGIOS_HOME}/libexec/utils.pm /usr/lib/nagios/plugins                            && \
    cd /tmp && rm -Rf nagios-plugins

RUN wget -O ${NAGIOS_HOME}/libexec/check_ncpa.py https://raw.githubusercontent.com/NagiosEnterprises/ncpa/v2.0.5/client/check_ncpa.py  && \
    chmod +x ${NAGIOS_HOME}/libexec/check_ncpa.py

RUN cd /tmp                                                                  && \
    git clone https://github.com/NagiosEnterprises/nrpe.git -b $NRPE_BRANCH  && \
    cd nrpe                                                                  && \
    ./configure                                   \
        --with-ssl=/usr/bin/openssl               \
        --with-ssl-lib=/usr/lib/x86_64-linux-gnu  \
                                                                             && \
    make check_nrpe                                                          && \
    cp src/check_nrpe ${NAGIOS_HOME}/libexec/                                && \
    make clean                                                               && \
    cd /tmp && rm -Rf nrpe

RUN cd /tmp                                                          && \
    git clone https://git.code.sf.net/p/nagiosgraph/git nagiosgraph  && \
    cd nagiosgraph                                                   && \
    ./install.pl --install                                      \
        --prefix /opt/nagiosgraph                               \
        --nagios-user ${NAGIOS_USER}                            \
        --www-user ${NAGIOS_USER}                               \
        --nagios-perfdata-file ${NAGIOS_HOME}/var/perfdata.log  \
        --nagios-cgi-url /cgi-bin                               \
                                                                     && \
    cp share/nagiosgraph.ssi ${NAGIOS_HOME}/share/ssi/common-header.ssi
    #cd /tmp && rm -Rf nagiosgraph/*

#RUN cd /opt                                                                         && \
#    pip install pymssql                                                             && \
#    git clone https://github.com/willixix/naglio-plugins.git     WL-Nagios-Plugins  && \
#    git clone https://github.com/JasonRivers/nagios-plugins.git  JR-Nagios-Plugins  && \
#    git clone https://github.com/justintime/nagios-plugins.git   JE-Nagios-Plugins  && \
#    git clone https://github.com/nagiosenterprises/check_mssql_collection.git   nagios-mssql  && \
#    chmod +x /opt/WL-Nagios-Plugins/check*                                          && \
#    chmod +x /opt/JE-Nagios-Plugins/check_mem/check_mem.pl                          && \
#    cp /opt/JE-Nagios-Plugins/check_mem/check_mem.pl ${NAGIOS_HOME}/libexec/           && \
#    cp /opt/nagios-mssql/check_mssql_database.py ${NAGIOS_HOME}/libexec/                         && \
#    cp /opt/nagios-mssql/check_mssql_server.py ${NAGIOS_HOME}/libexec/


RUN sed -i.bak 's/.*\=www\-data//g' /etc/apache2/envvars
RUN echo "<VirtualHost *:80>\n\
  ServerName ${NAGIOS_FQDN}\n\
  Redirect / https://${NAGIOS_FQDN}\n\
</VirtualHost>" > /etc/apache2/sites-enabled/000-default.conf && \
    ln -s /etc/apache2/mods-available/cgi.load /etc/apache2/mods-enabled/cgi.load

#apache ssl
RUN cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-enabled/ssl.conf                                                     && \
    sed -i "s,ServerAdmin.*,ServerAdmin joost.kuif@gmail.com," /etc/apache2/sites-enabled/ssl.conf                                           && \
    sed -i "s,DocumentRoot.*,DocumentRoot ${NAGIOS_HOME}/share," /etc/apache2/sites-enabled/ssl.conf                                           && \
    sed -i "s,SSLCertificateFile.*,SSLCertificateFile /opt/nagios/certs/nagios_nexus-nederland_nl.pem," /etc/apache2/sites-enabled/ssl.conf    && \
    sed -i "s,SSLCertificateKeyFile.*,SSLCertificateKeyFile /opt/nagios/certs/nagios_nexus-nederland_nl.key," /etc/apache2/sites-enabled/ssl.conf && \
    sed -i "s,#SSLCertificateChainFile.*,SSLCertificateChainFile /opt/nagios/certs/TrustProviderBVTLSRSACAG1_cer_X509Cert.cer," /etc/apache2/sites-enabled/ssl.conf

RUN mkdir -p -m 0755 /usr/share/snmp/mibs                     && \
    mkdir -p         ${NAGIOS_HOME}/etc/conf.d                && \
    mkdir -p         ${NAGIOS_HOME}/etc/monitor               && \
    mkdir -p -m 700  ${NAGIOS_HOME}/.ssh                      && \
    chown ${NAGIOS_USER}:${NAGIOS_GROUP} ${NAGIOS_HOME}/.ssh  && \
    touch /usr/share/snmp/mibs/.foo                           && \
    ln -s /usr/share/snmp/mibs ${NAGIOS_HOME}/libexec/mibs    && \
    ln -s ${NAGIOS_HOME}/bin/nagios /usr/local/bin/nagios     && \
    download-mibs && echo "mibs +ALL" > /etc/snmp/snmp.conf

RUN sed -i 's,/bin/mail,/usr/bin/mail,' ${NAGIOS_HOME}/etc/objects/commands.cfg  && \
    sed -i 's,/usr/usr,/usr,'           ${NAGIOS_HOME}/etc/objects/commands.cfg

RUN cp /etc/services /var/spool/postfix/etc/  && \
    echo "smtp_address_preference = ipv4" >> /etc/postfix/main.cf

RUN rm -rf /etc/rsyslog.d /etc/rsyslog.conf

RUN rm -rf /etc/sv/getty-5

ADD overlay /

ENV TZ=${NAGIOS_TIMEZONE}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN echo "use_timezone=${NAGIOS_TIMEZONE}" >> ${NAGIOS_HOME}/etc/nagios.cfg

# Copy example config in-case the user has started with empty var or etc

RUN mkdir -p /orig/var && mkdir -p /orig/etc  && \
    cp -Rp ${NAGIOS_HOME}/var/* /orig/var/       && \
    cp -Rp ${NAGIOS_HOME}/etc/* /orig/etc/

RUN a2enmod session         && \
    a2enmod session_cookie  && \
    a2enmod session_crypto  && \
    a2enmod auth_form       && \
    a2enmod request         && \
    a2enmod ssl             && \
    a2enmod authnz_ldap     && \
    a2enmod ldap

RUN chmod +x /usr/local/bin/start_nagios        && \
    chmod +x /etc/sv/apache/run                 && \
    chmod +x /etc/sv/nagios/run                 && \
    chmod +x /etc/sv/postfix/run                 && \
    chmod +x /etc/sv/rsyslog/run                 && \
    chmod +x /opt/nagiosgraph/etc/fix-nagiosgraph-multiple-selection.sh

RUN cd /opt/nagiosgraph/etc && \
    sh fix-nagiosgraph-multiple-selection.sh

RUN rm /opt/nagiosgraph/etc/fix-nagiosgraph-multiple-selection.sh

# enable all runit services
RUN ln -s /etc/sv/* /etc/service

ENV APACHE_LOCK_DIR /var/run
ENV APACHE_LOG_DIR /var/log/apache2

#Set ServerName for Apache
RUN echo "ServerName ${NAGIOS_FQDN}" > /etc/apache2/conf-available/servername.conf    && \
    ln -s /etc/apache2/conf-available/servername.conf /etc/apache2/conf-enabled/servername.conf

#Link apache2 configuration from outside
RUN rm /etc/apache2/sites-available/nagios.conf && rm /etc/apache2/sites-enabled/nagios.conf && rm /etc/apache2/conf-enabled/serve-cgi-bin.conf && \
    ln -s /opt/nagios/apache2/nagios.conf /etc/apache2/sites-available/nagios.conf && \
    ln -s /etc/apache2/sites-available/nagios.conf /etc/apache2/sites-enabled/nagios.conf

VOLUME "${NAGIOS_HOME}/var" "${NAGIOS_HOME}/etc" "${NAGIOS_HOME}/certs" "${NAGIOS_HOME}/apache2" "/var/log/apache2" "/opt/custom-nagios-plugins" "/opt/nagiosgraph/var" "/opt/nagiosgraph/etc"

#In deze oracleinstall worden ook packages geinstaleerd maar daar falen ze, ze zijn daarom in de grote apt-get install (bovenin dit script) toegevoegd
RUN cd /opt/oracle                                                                         && \
    wget https://assets.nagios.com/downloads/general/scripts/oracleinstall.sh              && \
    chmod +x oracleinstall.sh                                                              && \
    bash ./oracleinstall.sh                                                                && \
    ldconfig -v

#upgrade and cleanup
RUN apt-get upgrade -y && \
   apt-get clean && \
   rm -Rf /var/lib/apt/lists/*

#workaround for missing /var/run/samba/msg.lock dir
RUN net status sessions && \
   chmod +wx /var/run/samba/msg.lock

EXPOSE 80 443

CMD [ "/usr/local/bin/start_nagios" ]
