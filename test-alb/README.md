# ALB Test Application

This directory contains sample Kubernetes manifests to test the AWS Load Balancer Controller integration with your EKS cluster.

## Files

- **deployment.yaml**: Creates a test application with 2 replicas using nginx with custom HTML
- **deployment-simple.yaml**: Alternative simple deployment using http-echo (lightweight)
- **service.yaml**: Creates a ClusterIP service for the test application
- **ingress.yaml**: Creates an Ingress resource that triggers ALB creation
- **advanced-ingress.yaml**: Example of advanced ALB configuration with SSL, WAF, etc.
- **quick-test.sh**: Automated test script

## Quick Start

### 1. Deploy the Test Application

**Option A: Using nginx deployment (recommended for visual testing)**
```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

**Option B: Using simple http-echo deployment (lightweight)**
```bash
kubectl apply -f deployment-simple.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
```

**Option C: Apply all at once**
```bash
kubectl apply -f deployment.yaml -f service.yaml -f ingress.yaml
```

### 2. Verify Deployment

```bash
# Check deployment status
kubectl get deployment test-app

# Check pods
kubectl get pods -l app=test-app

# Check service
kubectl get service test-app

# Check ingress (wait for ALB DNS name to be populated)
kubectl get ingress test-app
```

### 3. Get ALB DNS Name

```bash
# Get ALB DNS name
kubectl get ingress test-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Or with watch to see when it's ready
watch -n 5 'kubectl get ingress test-app'
```

### 4. Test the Application

```bash
# Get ALB DNS name
ALB_DNS=$(kubectl get ingress test-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test HTTP endpoint
curl http://$ALB_DNS

# Test health endpoint
curl http://$ALB_DNS/health

# Test multiple times to see load balancing
for i in {1..5}; do
  echo "Request $i:"
  curl -s http://$ALB_DNS | grep "Pod Name" || echo "Response received"
  sleep 2
done
```

## Expected Results

1. **Deployment**: 2 pods running in `Ready` state
2. **Service**: ClusterIP service with endpoints pointing to pods
3. **Ingress**: ALB DNS name populated in status (may take 2-5 minutes)
4. **ALB**: Created in AWS with:
   - Internet-facing scheme
   - Target groups with healthy targets
   - Security group allowing HTTP traffic
5. **Application**: Accessible via ALB DNS name, showing pod information

## Customization

### Internal ALB

To create an internal ALB, change the annotation in `ingress.yaml`:

```yaml
alb.ingress.kubernetes.io/scheme: internal
```

### HTTPS/SSL

To enable HTTPS, uncomment and configure SSL annotations in `ingress.yaml`:

```yaml
alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:region:account:certificate/cert-id
alb.ingress.kubernetes.io/ssl-redirect: "443"
alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
```

### Path-Based Routing

To add path-based routing, modify the `ingress.yaml`:

```yaml
spec:
  rules:
  - http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
```

### Host-Based Routing

To add host-based routing:

```yaml
spec:
  rules:
  - host: app1.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
  - host: app2.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
```

## Troubleshooting

### ALB Not Created

1. Check ALB Controller logs:
   ```bash
   kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
   ```

2. Check Ingress events:
   ```bash
   kubectl describe ingress test-app
   ```

3. Verify subnets are tagged correctly (ALB Controller needs subnets tagged for auto-discovery)

### Targets Unhealthy

1. Check target health:
   ```bash
   # Get ALB ARN from AWS console or CLI
   aws elbv2 describe-target-health --target-group-arn <arn>
   ```

2. Check pod status:
   ```bash
   kubectl get pods -l app=test-app
   kubectl describe pod <pod-name>
   ```

3. Check service endpoints:
   ```bash
   kubectl get endpoints test-app
   ```

4. Verify security groups allow traffic between ALB and nodes

### Cannot Access ALB

1. Verify ALB is active:
   ```bash
   aws elbv2 describe-load-balancers --query "LoadBalancers[?DNSName=='<alb-dns>']"
   ```

2. Check security group rules allow your IP
3. Verify DNS resolution:
   ```bash
   nslookup <alb-dns>
   ```

## Cleanup

To remove all test resources:

```bash
kubectl delete -f ingress.yaml
kubectl delete -f service.yaml
kubectl delete -f deployment.yaml
```

The ALB will be automatically deleted by the ALB Controller when the Ingress is removed (may take a few minutes).

## Additional Resources

- [AWS Load Balancer Controller Annotations](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/guide/ingress/annotations/)
- [Kubernetes Ingress Documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)

