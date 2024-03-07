FROM tomcat:9-jdk8 as build

ARG XNAT_VERSION=1.8.9.2
ARG XNAT_ROOT=/data/xnat
ARG XNAT_HOME=/data/xnat/home
ARG XNAT_DATASOURCE_DRIVER=org.postgresql.Driver
ARG XNAT_DATASOURCE_URL=jdbc:postgresql://xnat-postgresql/xnat
ARG XNAT_DATASOURCE_USERNAME=xnat
ARG XNAT_DATASOURCE_PASSWORD=xnat
ARG XNAT_SMTP_ENABLED=false
ARG TOMCAT_XNAT_FOLDER=ROOT
ARG TOMCAT_XNAT_FOLDER_PATH=${CATALINA_HOME}/webapps/${TOMCAT_XNAT_FOLDER}

# default plugins for AIS
ARG container_service_ver=3.4.2-fat
ARG ldap_auth_ver=1.1.0
ARG ohif_viewer_ver=3.6.0
ARG openid_auth_ver=1.3.1-xpl
ARG xsync_ver=1.6.0
ARG batch_launch_ver=0.6.0

# default environment variables
ENV CATALINA_OPTS="-Xms${XNAT_MIN_HEAP} -Xmx${XNAT_MAX_HEAP} -Dxnat.home=${XNAT_HOME}"
ENV XNAT_HOME=${XNAT_HOME}

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

RUN <<EOT
  rm -rf ${CATALINA_HOME}/webapps/*
  mkdir -p \
    ${TOMCAT_XNAT_FOLDER_PATH} \
    ${XNAT_HOME}/config \
    ${XNAT_HOME}/logs \
    ${XNAT_HOME}/plugins \
    ${XNAT_HOME}/work \
    ${XNAT_ROOT}/archive \
    ${XNAT_ROOT}/build \
    ${XNAT_ROOT}/cache \
    ${XNAT_ROOT}/ftp \
    ${XNAT_ROOT}/pipeline \
    ${XNAT_ROOT}/prearchive
EOT

RUN <<EOT
  wget --no-verbose -P /tmp \
    https://api.bitbucket.org/2.0/repositories/xnatdev/xnat-web/downloads/xnat-web-${XNAT_VERSION}.war
  unzip -o -d ${TOMCAT_XNAT_FOLDER_PATH} /tmp/xnat-web-${XNAT_VERSION}.war
  sed -i \
    's/ch.qos.logback.core.rolling.RollingFileAppender/ch.qos.logback.core.ConsoleAppender/' \
    ${TOMCAT_XNAT_FOLDER_PATH}/WEB-INF/classes/logback.xml
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
ARG XNAT_VERSION=1.8.9.2
ARG XNAT_ROOT=/data/xnat
ARG XNAT_HOME=/data/xnat/home

RUN <<EOT
  rm -rf /var/lib/apt/lists/*
  rm -rf ${CATALINA_HOME}/webapps/*
EOT

COPY --from=build ${CATALINA_HOME}/webapps/ ${CATALINA_HOME}/webapps/
COPY --from=build ${XNAT_HOME} ${XNAT_HOME}
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
