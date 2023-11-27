# vim:set ft=dockerfile:
#
# Copyright The CloudNativePG Contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
FROM postgis/postgis:16-3.4

# Do not split the description, otherwise we will see a blank space in the labels
LABEL name="PostgreSQL + PostGIS Container Images" \
      vendor="The CloudNativePG Contributors" \
      version="${PG_VERSION}" \
      release="11" \
      summary="PostgreSQL + PostGIS + anonymizer Container images." \
      description="This Docker image contains PostgreSQL, PostGIS and Barman Cloud based on Postgres 16-3.4. PgAnonymizer was manually added"

COPY requirements.txt /
COPY ./anon ./anon

# Install additional extensions
RUN set -xe; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		"postgresql-${PG_MAJOR}-pgaudit" \
		"postgresql-${PG_MAJOR}-pg-failover-slots" \
		"postgresql-${PG_MAJOR}-pgrouting" \
		"make" \
		"postgresql-server-dev-16" \
		"gcc"; \
	rm -fr /tmp/* ; \
	rm -rf /var/lib/apt/lists/*;


WORKDIR /anon

RUN	ls -l; \
	make extension; \
 	make install;

# Install barman-cloud

	WORKDIR ..
RUN set -xe; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		python3-pip \
		python3-psycopg2 \
		python3-setuptools \
	; \
	pip3 install --upgrade pip; \
# TODO: Remove --no-deps once https://github.com/pypa/pip/issues/9644 is solved
	pip3 install --no-deps -r requirements.txt; \
    rm -rf /var/lib/apt/lists/*;

COPY ./anon/docker/09_init_anon.sh /docker-entrypoint-initdb.d/
RUN chmod +x /docker-entrypoint-initdb.d/09_init_anon.sh


# # Change the uid of postgres to 26
RUN chown -R postgres /var/lib/postgresql/data && usermod -u 26 postgres  
USER 26
