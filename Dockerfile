# vim:set ft=dockerfile:
#
# Copyright The CloudNativePG Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
FROM postgres:18

# Set environment variables
ENV PG_MAJOR=18

# Do not split the description, otherwise we will see a blank space in the labels
LABEL name="PostgreSQL + TimescaleDB + PostGIS Container Images" \
	version="${PG_VERSION}" \
	release="59" \
	summary="PostgreSQL + TimescaleDB + PostGIS + anon Container images." \
	description="This Docker image contains PostgreSQL, TimescaleDB, PostGIS and Barman Cloud based on Postgres 18-debian."

COPY requirements.txt /

# Install build dependencies and tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    clang \
    llvm \
    git \
    cmake \
    python3 \
    python3-pip \
    python3-dev \
    postgresql-server-dev-18 \
    libffi-dev \
    libssl-dev \
    libsnappy-dev \
    cargo \
    rustc \
    wget \
    ca-certificates \
    autoconf \
    automake \
    libtool \
    libkrb5-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libxml2-dev \
    libjson-c-dev \
    libprotobuf-c-dev \
    protobuf-c-compiler \
    libpq-dev \
    python3-psycopg2 \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Install PostGIS from source (since we are not using postgis base image)
RUN set -ex \
    && git clone https://github.com/postgis/postgis.git \
    && cd postgis \
    && git checkout 3.6.1 \
    && ./autogen.sh \
    && ./configure \
    && make \
    && make install \
    && cd .. && rm -rf postgis

# Install TimescaleDB
# Building from source
RUN set -ex \
    && git clone https://github.com/timescale/timescaledb.git \
    && cd timescaledb \
    && git checkout 2.23.1 \
    && ./bootstrap -DREGRESS_CHECKS=OFF \
    && cd build && make && make install \
    && cd ../.. && rm -rf timescaledb

# Install pgaudit, pgrouting, pgvector, pg_ivm
RUN set -ex \
    # pgaudit
    && git clone https://github.com/pgaudit/pgaudit.git \
    && cd pgaudit \
    && git checkout REL_18_STABLE \
    && make install USE_PGXS=1 \
    && cd .. && rm -rf pgaudit \
    # pgvector
    && git clone --branch v0.8.1 https://github.com/pgvector/pgvector.git \
    && cd pgvector \
    && make \
    && make install \
    && cd .. && rm -rf pgvector \
    # pg_ivm
    && git clone https://github.com/sraoss/pg_ivm.git \
    && cd pg_ivm \
    && make install \
    && cd .. && rm -rf pg_ivm

# Install barman-cloud
RUN set -xe; \
    export PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1; \
    # Install dependencies that might need compilation
    pip3 install psycopg2-binary setuptools --break-system-packages; \
	pip3 install --no-deps -r requirements.txt --break-system-packages;

# Install postgresql_anonymizer
RUN set -xe; \
    pip3 install pgxnclient --break-system-packages; \
    pgxn install postgresql_anonymizer; \
    # Cleanup build deps if desired to save space (omitted for safety in this step)
    rm -rf /root/.cache

# Change the uid of postgres to 26
# Debian based postgres image already has postgres user with uid 999 usually.
# We need to change it to 26 as per requirement.
RUN usermod -u 26 postgres

# Ensure /data directory exists and has correct permissions
RUN mkdir -p /data/postgres && chown -R postgres:postgres /data && chmod 700 /data/postgres

# CloudNativePG requires /var/lib/postgresql/data to be present for volume mounting
# The base image sets up /var/lib/postgresql/data.
# We recreate it to be sure it's clean and has correct permissions.
RUN rm -rf /var/lib/postgresql/data && mkdir -p /var/lib/postgresql/data && chown -R postgres:postgres /var/lib/postgresql/data && chmod 700 /var/lib/postgresql/data

# Verify directory exists and is NOT a symlink
RUN ls -ld /var/lib/postgresql/data

USER 26
