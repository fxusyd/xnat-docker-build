FROM tomcat:9-jdk8 as build

ARG XNAT_VERSION=1.8.9.2
ARG XNAT_ROOT=/data/xnat
ARG XNAT_HOME=/data/xnat/home

# default plugins for AIS
ARG container_service_ver=3.4.2-fat
ARG ldap_auth_ver=1.1.0
ARG ohif_viewer_ver=3.6.0
ARG openid_auth_ver=1.3.1-xpl
ARG xsync_ver=1.6.0
ARG batch_launch_ver=0.6.0

RUN <<EOT
  apt-get update
  apt-get install -y \
    less \
    postgresql-client \
    telnet \
    unzip \
    wget
  rm -rf /var/lib/apt/lists/*
EOT

# Setup XNAT base directory structure
RUN <<EOT
  mkdir -p \
    ${XNAT_ROOT}/archive \
    ${XNAT_ROOT}/build \
    ${XNAT_ROOT}/cache \
    ${XNAT_ROOT}/fileStore \
    ${XNAT_ROOT}/ftp \
    ${XNAT_HOME}/config/auth \
    ${XNAT_HOME}/logs \
    ${XNAT_HOME}/plugins \
    ${XNAT_HOME}/themes \
    ${XNAT_HOME}/work \
    ${XNAT_ROOT}/inbox \
    ${XNAT_ROOT}/pipeline \
    ${XNAT_ROOT}/prearchive
EOT

# Install XNAT web Java application
RUN <<EOT
  rm -rf ${CATALINA_HOME}/webapps/*
  mkdir -p ${CATALINA_HOME}/webapps/ROOT
  wget --no-verbose -P /tmp \
    https://api.bitbucket.org/2.0/repositories/xnatdev/xnat-web/downloads/xnat-web-${XNAT_VERSION}.war
  unzip -o -d ${CATALINA_HOME}/webapps/ROOT /tmp/xnat-web-${XNAT_VERSION}.war
EOT

# Download standard plugins
RUN <<EOT
  wget --no-verbose -P ${XNAT_HOME}/plugins \
    https://api.bitbucket.org/2.0/repositories/xnatdev/container-service/downloads/container-service-${container_service_ver}.jar
  wget --no-verbose -P ${XNAT_HOME}/plugins \
    https://api.bitbucket.org/2.0/repositories/xnatx/ldap-auth-plugin/downloads/ldap-auth-plugin-${ldap_auth_ver}.jar
  wget --no-verbose -P ${XNAT_HOME}/plugins \
    https://api.bitbucket.org/2.0/repositories/icrimaginginformatics/ohif-viewer-xnat-plugin/downloads/ohif-viewer-${ohif_viewer_ver}.jar
  wget --no-verbose -P ${XNAT_HOME}/plugins \
    https://api.bitbucket.org/2.0/repositories/xnatx/openid-auth-plugin/downloads/openid-auth-plugin-${openid_auth_ver}.jar
  wget --no-verbose -P ${XNAT_HOME}/plugins \
    https://api.bitbucket.org/2.0/repositories/xnatdev/xsync/downloads/xsync-plugin-all-${xsync_ver}.jar
  wget --no-verbose -P ${XNAT_HOME}/plugins \
    https://api.bitbucket.org/2.0/repositories/xnatx/xnatx-batch-launch-plugin/downloads/batch-launch-${batch_launch_ver}.jar
EOT


FROM tomcat:9-jdk8
ARG XNAT_ROOT=/data/xnat
ARG XNAT_HOME=/data/xnat/home
ARG XNAT_VERSION=1.8.9.2

RUN <<EOT
  rm -rf /var/lib/apt/lists/*
  rm -rf ${CATALINA_HOME}/webapps/*
EOT

COPY --from=build ${CATALINA_HOME}/webapps/ ${CATALINA_HOME}/webapps/
COPY --from=build ${XNAT_ROOT} ${XNAT_ROOT}

RUN <<EOT
  sed -i \
    's/ch.qos.logback.core.rolling.RollingFileAppender/ch.qos.logback.core.ConsoleAppender/' \
    ${CATALINA_HOME}/webapps/ROOT/WEB-INF/classes/logback.xml
EOT

COPY --chmod=0755 ./setenv.sh ${CATALINA_HOME}/bin/setenv.sh
COPY --chmod=0755 ./entrypoint.sh /usr/local/bin/entrypoint.sh
COPY ./xnat-conf.properties ${XNAT_HOME}/config/xnat-conf.properties

ENV XNAT_HOME=${XNAT_HOME} \
    XNAT_VERSION=$XNAT_VERSION \
    TZ=Australia/Sydney

LABEL org.opencontainers.image.source https://github.com/australian-imaging-service/xnat-build
LABEL maintainer="AIS Team ais-team@ais"

ENTRYPOINT ["entrypoint.sh"]
CMD ["catalina.sh","run"]
