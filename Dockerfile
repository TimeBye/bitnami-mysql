# https://downloads.bitnami.com/files/stacksmith/mysql-5.7.43-2-linux-amd64-debian-11.tar.gz --> BUILD.txt
FROM docker.io/bitnami/debian-base-buildpack:bullseye-r6 AS build
RUN apt-get update -y
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends libaio-dev libnuma1 libsasl2-modules-gssapi-mit libkrb5-dev
RUN mkdir -p /tmp/sources/mysql
RUN mkdir -p /bitnami/blacksmith-sandox/mysql-5.7.44.tmp
RUN curl https://cdn.mysql.com/Downloads/MySQL-5.7/mysql-5.7.44.tar.gz --output /tmp/sources/mysql/mysql-5.7.44.tar.gz
RUN tar --no-same-owner -C /bitnami/blacksmith-sandox/mysql-5.7.44.tmp -xf /tmp/sources/mysql/mysql-5.7.44.tar.gz
WORKDIR /bitnami/blacksmith-sandox/mysql-5.7.44.tmp/mysql-5.7.44
RUN cmake  -DDOWNLOAD_BOOST=1 -DWITH_BOOST=/tmp/boost/ -DBUILD_CONFIG=mysql_release -DWITH_AUTHENTICATION_LDAP=1 -DCMAKE_INSTALL_PREFIX=/opt/bitnami/mysql -DSYSCONFDIR=/opt/bitnami/mysql/conf -DDEFAULT_SYSCONFDIR=/opt/bitnami/mysql/conf -DFORCE_INSOURCE_BUILD=1
RUN make  --jobs=9
RUN make  install --jobs=9
RUN make  clean
RUN strip  /opt/bitnami/mysql/bin/innochecksum
RUN strip  /opt/bitnami/mysql/bin/lz4_decompress
RUN strip  /opt/bitnami/mysql/bin/my_print_defaults
RUN strip  /opt/bitnami/mysql/bin/myisam_ftdump
RUN strip  /opt/bitnami/mysql/bin/myisamchk
RUN strip  /opt/bitnami/mysql/bin/myisamlog
RUN strip  /opt/bitnami/mysql/bin/myisampack
RUN strip  /opt/bitnami/mysql/bin/mysql
RUN strip  /opt/bitnami/mysql/bin/mysql_config_editor
RUN strip  /opt/bitnami/mysql/bin/mysql_install_db
RUN strip  /opt/bitnami/mysql/bin/mysql_plugin
RUN strip  /opt/bitnami/mysql/bin/mysql_secure_installation
RUN strip  /opt/bitnami/mysql/bin/mysql_ssl_rsa_setup
RUN strip  /opt/bitnami/mysql/bin/mysql_tzinfo_to_sql
RUN strip  /opt/bitnami/mysql/bin/mysql_upgrade
RUN strip  /opt/bitnami/mysql/bin/mysqladmin
RUN strip  /opt/bitnami/mysql/bin/mysqlbinlog
RUN strip  /opt/bitnami/mysql/bin/mysqlcheck
RUN strip  /opt/bitnami/mysql/bin/mysqld
RUN strip  /opt/bitnami/mysql/bin/mysqldump
RUN strip  /opt/bitnami/mysql/bin/mysqlimport
RUN strip  /opt/bitnami/mysql/bin/mysqlpump
RUN strip  /opt/bitnami/mysql/bin/mysqlshow
RUN strip  /opt/bitnami/mysql/bin/mysqlslap
RUN strip  /opt/bitnami/mysql/bin/perror
RUN strip  /opt/bitnami/mysql/bin/replace
RUN strip  /opt/bitnami/mysql/bin/resolve_stack_dump
RUN strip  /opt/bitnami/mysql/bin/resolveip
RUN strip  /opt/bitnami/mysql/bin/zlib_decompress

# Copyright VMware, Inc.
# SPDX-License-Identifier: APACHE-2.0
FROM docker.io/bitnami/minideb:bullseye

ARG TARGETARCH

LABEL com.vmware.cp.artifact.flavor="sha256:1e1b4657a77f0d47e9220f0c37b9bf7802581b93214fff7d1bd2364c8bf22e8e" \
      org.opencontainers.image.base.name="docker.io/bitnami/minideb:bullseye" \
      org.opencontainers.image.created="2023-10-09T17:45:01Z" \
      org.opencontainers.image.description="Application packaged by VMware, Inc" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.ref.name="5.7.44-debian-11-r73" \
      org.opencontainers.image.title="mysql" \
      org.opencontainers.image.vendor="VMware, Inc." \
      org.opencontainers.image.version="5.7.44"

ENV HOME="/" \
    OS_ARCH="${TARGETARCH:-amd64}" \
    OS_FLAVOUR="debian-11" \
    OS_NAME="linux"

COPY prebuildfs /
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# Install required system packages and dependencies
RUN install_packages ca-certificates curl gcc-10 libaio1 libcom-err2 libcrypt1 libgcc-s1 libgssapi-krb5-2 libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 libsasl2-2 libssl1.1 libstdc++6 libtinfo6 libtirpc3 procps psmisc
RUN mkdir -p /tmp/bitnami/pkg/cache/ && cd /tmp/bitnami/pkg/cache/ && \
    COMPONENTS=( \
      "ini-file-1.4.6-1-linux-${OS_ARCH}-debian-11" \
    ) && \
    for COMPONENT in "${COMPONENTS[@]}"; do \
      if [ ! -f "${COMPONENT}.tar.gz" ]; then \
        curl -SsLf "https://downloads.bitnami.com/files/stacksmith/${COMPONENT}.tar.gz" -O ; \
        curl -SsLf "https://downloads.bitnami.com/files/stacksmith/${COMPONENT}.tar.gz.sha256" -O ; \
      fi && \
      sha256sum -c "${COMPONENT}.tar.gz.sha256" && \
      tar -zxf "${COMPONENT}.tar.gz" -C /opt/bitnami --strip-components=2 --no-same-owner --wildcards '*/files' && \
      rm -rf "${COMPONENT}".tar.gz{,.sha256} ; \
    done
RUN apt-get autoremove --purge -y curl && \
    apt-get update && apt-get upgrade -y && \
    apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives
RUN chmod g+rwX /opt/bitnami
RUN mkdir /docker-entrypoint-initdb.d

COPY rootfs /
COPY --from=build /opt/bitnami/mysql /opt/bitnami/mysql
RUN /opt/bitnami/scripts/mysql/postunpack.sh
ENV APP_VERSION="5.7.44" \
    BITNAMI_APP_NAME="mysql" \
    PATH="/opt/bitnami/common/bin:/opt/bitnami/mysql/bin:/opt/bitnami/mysql/sbin:$PATH"

EXPOSE 3306

USER 1001
ENTRYPOINT [ "/opt/bitnami/scripts/mysql/entrypoint.sh" ]
CMD [ "/opt/bitnami/scripts/mysql/run.sh" ]
