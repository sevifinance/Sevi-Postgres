**Postgres  and timescaledb + postgis + anon + pgvector**

Tag 18 is required for cloudnative pg work correctly

**build image:**

docker buildx build --platform linux/amd64,linux/arm64 -t ghcr.io/sevifinance/sevi-pg:18 .

docker tag ghcr.io/sevifinance/sevi-pg:18 ghcr.io/sevifinance/sevi-pg:latest

**then**

use private token to login to personal account

docker login ghcr.io -u grinono

**then**

docker push ghcr.io/sevifinance/sevi-pg:18

docker push ghcr.io/sevifinance/sevi-pg:latest

**RUN local**

docker run -d
  -p 5432:5432
  -e POSTGRES_PASSWORD=hallo
  ghcr.io/sevifinance/sevi-pg:18
