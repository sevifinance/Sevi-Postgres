**Postgres  and timescaledb + postgis + anon**

**build image:**

docker buildx build --platform linux/amd64,linux/arm64 -t ghcr.io/sevifinance/pggisanon:30 .

 docker tag ghcr.io/sevifinance/pggisanon:30 ghcr.io/sevifinance/pggisanon:latest

**then**

use private token to login to personal account

docker login ghcr.io -u grinono

**then**

docker push ghcr.io/sevifinance/pggisanon:30

docker push ghcr.io/sevifinance/pggisanon:latest


**RUN local**

docker run -d
  -p 5432:5432
  -e POSTGRES_PASSWORD=hallo
  ghcr.io/sevifinance/pggisanon:28
