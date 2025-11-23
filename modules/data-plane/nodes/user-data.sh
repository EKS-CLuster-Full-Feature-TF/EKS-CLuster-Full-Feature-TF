MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
/etc/eks/bootstrap.sh public-endpoint-cluster \
  --kubelet-extra-args '--max-pods=120' \
  --use-max-pods false

--==MYBOUNDARY==