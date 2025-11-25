#!/bin/bash

# Quick ALB Test Script
# This script automates the deployment and testing of the ALB test application

set -e

CLUSTER_NAME="${CLUSTER_NAME:-eks-ap1-prod-EKS-squad-1}"
REGION="${REGION:-ap-south-1}"
NAMESPACE="${NAMESPACE:-default}"

echo "=========================================="
echo "EKS ALB Test Script"
echo "=========================================="
echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"
echo "Namespace: $NAMESPACE"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_status "Checking prerequisites..."

# Check kubectl
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed"
    exit 1
fi

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed"
    exit 1
fi

# Check cluster connection
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to cluster. Please run: aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION"
    exit 1
fi

print_status "Prerequisites check passed"
echo ""

# Step 1: Deploy application
print_status "Step 1: Deploying test application..."
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml

# Wait for deployment to be ready
print_status "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/test-app -n $NAMESPACE || {
    print_error "Deployment failed to become ready"
    exit 1
}

print_status "Deployment ready"
echo ""

# Step 2: Deploy ingress
print_status "Step 2: Deploying Ingress (this will create ALB)..."
kubectl apply -f ingress.yaml

# Step 3: Wait for ALB to be created
print_status "Step 3: Waiting for ALB to be created (this may take 2-5 minutes)..."
print_warning "Please be patient, ALB creation can take several minutes"

MAX_WAIT=600  # 10 minutes
ELAPSED=0
ALB_DNS=""

while [ $ELAPSED -lt $MAX_WAIT ]; do
    ALB_DNS=$(kubectl get ingress test-app -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [ -n "$ALB_DNS" ]; then
        print_status "ALB created successfully!"
        echo "ALB DNS Name: $ALB_DNS"
        break
    fi
    
    echo -n "."
    sleep 10
    ELAPSED=$((ELAPSED + 10))
done

echo ""

if [ -z "$ALB_DNS" ]; then
    print_error "ALB creation timed out. Check ALB Controller logs:"
    echo "  kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller"
    exit 1
fi

# Step 4: Wait for ALB to be fully active
print_status "Step 4: Waiting for ALB to be fully active..."
sleep 30

# Step 5: Test the application
print_status "Step 5: Testing application endpoint..."

# Wait a bit more for DNS propagation
sleep 20

# Test endpoint
MAX_RETRIES=10
RETRY=0
SUCCESS=false

while [ $RETRY -lt $MAX_RETRIES ]; do
    if curl -s -f -m 10 "http://$ALB_DNS" > /dev/null 2>&1; then
        SUCCESS=true
        break
    fi
    
    print_warning "Attempt $((RETRY + 1))/$MAX_RETRIES: Endpoint not ready yet, retrying in 15 seconds..."
    sleep 15
    RETRY=$((RETRY + 1))
done

if [ "$SUCCESS" = false ]; then
    print_error "Failed to access application endpoint"
    echo "ALB DNS: $ALB_DNS"
    echo "Please check:"
    echo "  1. ALB status in AWS Console"
    echo "  2. Security group rules"
    echo "  3. Target group health"
    exit 1
fi

print_status "Application is accessible!"
echo ""

# Step 6: Display test results
print_status "Step 6: Test Results"
echo "=========================================="
echo "ALB DNS Name: $ALB_DNS"
echo ""

# Test HTTP endpoint
print_status "Testing HTTP endpoint..."
HTTP_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" "http://$ALB_DNS" || echo "HTTP_CODE:000")
HTTP_CODE=$(echo "$HTTP_RESPONSE" | grep "HTTP_CODE" | cut -d: -f2)

if [ "$HTTP_CODE" = "200" ]; then
    print_status "✓ HTTP endpoint responding (200 OK)"
else
    print_warning "HTTP endpoint returned code: $HTTP_CODE"
fi

# Test health endpoint
print_status "Testing health endpoint..."
HEALTH_RESPONSE=$(curl -s "http://$ALB_DNS/health" || echo "unhealthy")
if [ "$HEALTH_RESPONSE" = "healthy" ]; then
    print_status "✓ Health endpoint working"
else
    print_warning "Health endpoint returned: $HEALTH_RESPONSE"
fi

# Test load balancing
print_status "Testing load balancing (5 requests)..."
echo "Pod names from different requests:"
for i in {1..5}; do
    POD_INFO=$(curl -s "http://$ALB_DNS" | grep -o "Pod Name:.*" | head -1 || echo "N/A")
    echo "  Request $i: $POD_INFO"
    sleep 1
done

echo ""
print_status "=========================================="
print_status "Test Summary"
print_status "=========================================="
echo "✓ Deployment created and running"
echo "✓ Service created"
echo "✓ Ingress created"
echo "✓ ALB created: $ALB_DNS"
echo "✓ Application accessible"
echo ""
print_status "To view the application, open in browser:"
echo "  http://$ALB_DNS"
echo ""
print_status "To cleanup resources, run:"
echo "  kubectl delete -f ingress.yaml"
echo "  kubectl delete -f service.yaml"
echo "  kubectl delete -f deployment.yaml"
echo ""

