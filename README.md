**Postgres  and timescaledb + postgis + anon + pgvector**

Tag 16 is required for the tag re

**build image:**

docker buildx build --platform linux/amd64,linux/arm64 -t ghcr.io/sevifinance/pggisanon:17 .

docker tag ghcr.io/sevifinance/pggisanon:17 ghcr.io/sevifinance/pggisanon:latest

**then**

use private token to login to personal account

docker login ghcr.io -u grinono

**then**

docker push ghcr.io/sevifinance/pggisanon:17

docker push ghcr.io/sevifinance/pggisanon:latest

**RUN local**

docker run -d
  -p 5432:5432
  -e POSTGRES_PASSWORD=hallo
  ghcr.io/sevifinance/pggisanon:28
