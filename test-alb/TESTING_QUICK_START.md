# Quick Start: ALB Testing

This is a quick reference guide for testing the ALB integration.

## Prerequisites

1. **Configure kubectl:**
   ```bash
   CLUSTER_NAME="eks-ap1-prod-EKS-squad-1"
   REGION="ap-south-1"
   aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION --profile pushpender-credentials
   ```

2. **Verify cluster access:**
   ```bash
   kubectl get nodes
   ```

## Quick Test (3 Steps)

### Step 1: Deploy Application
```bash
kubectl apply -f deployment.yaml -f service.yaml -f ingress.yaml
```

### Step 2: Wait for ALB (2-5 minutes)
```bash
# Watch for ALB DNS name
watch -n 10 'kubectl get ingress test-app'

# Or get it directly when ready
kubectl get ingress test-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### Step 3: Test
```bash
ALB_DNS=$(kubectl get ingress test-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$ALB_DNS
```

## Automated Test

Run the automated test script:
```bash
cd test-alb
./quick-test.sh
```

## Verify Components

### Check ALB Controller
```bash
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

### Check Application
```bash
kubectl get deployment test-app
kubectl get pods -l app=test-app
kubectl get service test-app
kubectl get ingress test-app
```

### Check ALB in AWS
```bash
ALB_DNS=$(kubectl get ingress test-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
aws elbv2 describe-load-balancers \
  --region ap-south-1 \
  --profile pushpender-credentials \
  --query "LoadBalancers[?DNSName=='$ALB_DNS'].[LoadBalancerName,State.Code,Scheme]"
```

## Cleanup

```bash
kubectl delete -f ingress.yaml -f service.yaml -f deployment.yaml
```

## Troubleshooting

**ALB not created?**
- Check ALB Controller logs: `kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller`
- Check Ingress events: `kubectl describe ingress test-app`

**Targets unhealthy?**
- Check pod status: `kubectl get pods -l app=test-app`
- Check service endpoints: `kubectl get endpoints test-app`
- Verify security groups allow traffic

**Cannot access ALB?**
- Verify ALB is active in AWS Console
- Check security group allows your IP
- Wait a few minutes for DNS propagation

For detailed testing procedures, see `../TESTING.md`

