FROM postgres:10

ENV POSTGIS_MAJOR=3
ENV POSTGIS_VERSION=3.0.0+dfsg-2~exp1.pgdg90+1

# ArcGIS support files
COPY src/postgres_support/10/*.so /usr/lib/postgresql/10/lib/

# Update and install tools packages
RUN apt-get update -y \
    && apt-get upgrade -y  \
    && apt-get install -y --no-install-recommends wget apt-transport-https ca-certificates

# TimescaleDB repository
RUN wget --quiet -O - https://packagecloud.io/timescale/timescaledb/gpgkey | apt-key add - \
    && sh -c "echo 'deb https://packagecloud.io/timescale/timescaledb/debian/ stretch main' > /etc/apt/sources.list.d/timescaledb.list" \
    && apt-get update \
    && apt-get install -y timescaledb-postgresql-10

# Install PostGIS
RUN apt-get install -y --no-install-recommends \
    postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR=$POSTGIS_VERSION \
    postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts=$POSTGIS_VERSION \
    postgis=$POSTGIS_VERSION

# Init scripts
RUN mkdir -p /docker-entrypoint-initdb.d
COPY src/initdb-postgis.sh /docker-entrypoint-initdb.d/postgis.sh
COPY src/update-postgis.sh /usr/local/bin
COPY src/timescaledb-tune.sh /docker-entrypoint-initdb.d/

# Remove unused package and cleanup.
RUN apt-get remove -y --purge wget apt-transport-https ca-certificates \
    && apt-get autoremove -y  \
    && rm -rf /var/lib/apt/lists/* 

ENV LD_LIBRARY_PATH=/usr/lib/postgresql/10/lib/
