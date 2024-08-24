**Postgres + postgis + anon**

**build image:**

docker build -t ghcr.io/sevifinance/pggisanon:25 .

docker tag ghcr.io/sevifinance/pggisanon:25 ghcr.io/sevifinance/pggisanon:latest

**then**

use private token to login to personal account

docker login ghcr.io -u grinono

**then**

docker push ghcr.io/sevifinance/pggisanon:25

docker push ghcr.io/sevifinance/pggisanon:latest
