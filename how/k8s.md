# Kubernetes Cheat Sheet

Container orchestration. Pods, deployments, services, debugging.

## Quick Reference

| Resource   | Purpose                                          | Key Commands                |
| ---------- | ------------------------------------------------ | --------------------------- |
| Pod        | Smallest deployable unit, one or more containers | `get`, `describe`, `logs`   |
| Deployment | Manages ReplicaSets, handles rollouts            | `apply`, `scale`, `rollout` |
| Service    | Stable network endpoint for pods                 | `expose`, `port-forward`    |
| ConfigMap  | Configuration data as key-value pairs            | `create configmap`          |
| Secret     | Sensitive data (base64 encoded)                  | `create secret`             |
| Namespace  | Virtual cluster for resource isolation           | `-n`, `--all-namespaces`    |

## Cluster Context

```bash
kubectl cluster-info                  # Display cluster info
kubectl version                       # Client and server version
kubectl get nodes                     # List nodes in cluster
kubectl get nodes -o wide             # With IP addresses

# Context management
kubectl config current-context        # Show current context
kubectl config get-contexts           # List all contexts
kubectl config use-context <name>     # Switch context
kubectl config set-context --current --namespace=<ns>  # Set default namespace
```

## Viewing Resources

```bash
# Basic listing
kubectl get pods                      # Pods in current namespace
kubectl get pods -n <namespace>       # Pods in specific namespace
kubectl get pods -A                   # Pods across all namespaces
kubectl get pods -o wide              # With node and IP info
kubectl get pods -w                   # Watch for changes

# Multiple resource types
kubectl get all                       # Common resources
kubectl get pods,svc,deploy           # Specific types
kubectl get all -A                    # Everything everywhere

# Output formats
kubectl get pods -o yaml              # YAML output
kubectl get pods -o json              # JSON output
kubectl get pods -o name              # Just names

# Describe for details
kubectl describe pod <name>           # Detailed pod info with events
kubectl describe node <name>          # Node details
kubectl describe deploy <name>        # Deployment details
```

## Pods

```bash
# Run a pod
kubectl run nginx --image=nginx       # Create pod imperatively
kubectl run debug --image=busybox -it --rm -- sh  # Temporary debug pod

# Logs
kubectl logs <pod>                    # View logs
kubectl logs <pod> -c <container>     # Specific container
kubectl logs <pod> --previous         # Previous container instance
kubectl logs <pod> -f                 # Follow/stream logs
kubectl logs <pod> --tail=100         # Last 100 lines
kubectl logs -l app=nginx             # By label selector

# Execute commands
kubectl exec <pod> -- ls /app         # Run command in pod
kubectl exec -it <pod> -- /bin/sh     # Interactive shell
kubectl exec -it <pod> -c <container> -- sh  # Specific container

# Copy files
kubectl cp <pod>:/path ./local        # From pod to local
kubectl cp ./local <pod>:/path        # From local to pod

# Port forwarding
kubectl port-forward <pod> 8080:80    # Forward local:pod
kubectl port-forward svc/<name> 8080:80  # Forward to service
```

## Deployments

```bash
# Create
kubectl create deployment nginx --image=nginx
kubectl create deployment nginx --image=nginx --replicas=3

# Apply from manifest
kubectl apply -f deployment.yaml      # Create or update
kubectl apply -f ./manifests/         # All files in directory
kubectl apply -f https://url/manifest.yaml  # From URL

# Scale
kubectl scale deploy <name> --replicas=5
kubectl autoscale deploy <name> --min=2 --max=10 --cpu-percent=80

# Update image (rolling update)
kubectl set image deploy/<name> <container>=<image:tag>
kubectl set image deploy/nginx nginx=nginx:1.25

# Rollout management
kubectl rollout status deploy/<name>  # Watch rollout progress
kubectl rollout history deploy/<name> # View history
kubectl rollout undo deploy/<name>    # Rollback to previous
kubectl rollout undo deploy/<name> --to-revision=2  # Specific revision
kubectl rollout restart deploy/<name> # Restart all pods
kubectl rollout pause deploy/<name>   # Pause rollout
kubectl rollout resume deploy/<name>  # Resume rollout
```

## Services

```bash
# Expose deployment
kubectl expose deploy <name> --port=80 --target-port=8080
kubectl expose deploy <name> --type=NodePort --port=80
kubectl expose deploy <name> --type=LoadBalancer --port=80

# Types
# ClusterIP  — internal only (default)
# NodePort   — exposed on each node's IP at static port
# LoadBalancer — external load balancer (cloud/OrbStack)

# Get endpoints
kubectl get endpoints <service>
kubectl get svc <name> -o wide
```

## ConfigMaps & Secrets

```bash
# ConfigMap
kubectl create configmap <name> --from-literal=key=value
kubectl create configmap <name> --from-file=config.properties
kubectl create configmap <name> --from-env-file=.env
kubectl get configmap <name> -o yaml

# Secrets
kubectl create secret generic <name> --from-literal=password=secret
kubectl create secret generic <name> --from-file=./credentials
kubectl create secret docker-registry <name> \
  --docker-server=<url> --docker-username=<user> --docker-password=<pass>

# View secret (base64 decoded)
kubectl get secret <name> -o jsonpath='{.data.password}' | base64 -d
```

## Namespaces

```bash
kubectl get namespaces                # List namespaces
kubectl create namespace <name>       # Create namespace
kubectl delete namespace <name>       # Delete (and all resources in it)

# Set default namespace
kubectl config set-context --current --namespace=<name>

# Shorthand for namespace flag
kubectl get pods -n kube-system
kubectl get pods --all-namespaces     # or -A
```

## Labels & Selectors

```bash
# Add/update labels
kubectl label pod <name> env=prod
kubectl label pod <name> env=staging --overwrite

# Remove label
kubectl label pod <name> env-

# Select by label
kubectl get pods -l app=nginx
kubectl get pods -l 'env in (prod,staging)'
kubectl get pods -l app=nginx,env=prod
kubectl delete pods -l app=test
```

## Debugging

### The Workflow: get → describe → logs

```bash
# 1. Get overview — what's the status?
kubectl get pods
kubectl get events --sort-by='.lastTimestamp'

# 2. Describe — what happened? (scheduling, mounts, probes)
kubectl describe pod <name>

# 3. Logs — what's the app saying?
kubectl logs <pod> --tail=50
kubectl logs <pod> --previous        # If container restarted
```

### Common Pod States

| State             | Meaning                           | Check                       |
| ----------------- | --------------------------------- | --------------------------- |
| Pending           | Not scheduled yet                 | `describe` for events       |
| ContainerCreating | Pulling image or mounting volumes | `describe` for events       |
| ImagePullBackOff  | Can't pull image                  | Image name, registry auth   |
| CrashLoopBackOff  | Container keeps crashing          | `logs --previous`           |
| Running           | Container is running              | May still be unhealthy      |
| Terminating       | Being deleted                     | Finalizers, stuck processes |

### Debug Commands

```bash
# Check pod events
kubectl describe pod <name> | grep -A 20 Events

# Check resource usage
kubectl top pods
kubectl top nodes

# Debug with ephemeral container (k8s 1.23+)
kubectl debug -it <pod> --image=busybox --target=<container>

# Run debug pod in same namespace
kubectl run debug --image=nicolaka/netshoot -it --rm -- /bin/bash

# Check DNS resolution
kubectl run test --image=busybox -it --rm -- nslookup kubernetes

# Check service connectivity
kubectl run test --image=curlimages/curl -it --rm -- curl http://<service>:<port>
```

## Local Development with OrbStack

OrbStack provides a lightweight local Kubernetes cluster on macOS.

### Setup

```bash
# Enable Kubernetes in OrbStack settings, or:
orb start k8s                         # Start cluster
orb stop k8s                          # Stop cluster
orb restart k8s                       # Restart cluster
orb delete k8s                        # Delete cluster
```

### OrbStack Advantages

- **2-second startup** — Fast cluster initialization
- **Shared images** — Built Docker images immediately available to pods
- **Direct network access** — All service types accessible from Mac
- **Low resource usage** — Battery-friendly, minimal CPU/disk

### Network Access

```bash
# Services accessible directly from Mac:
# - ClusterIP:  Direct IP access
# - NodePort:   localhost:<port>
# - LoadBalancer: *.k8s.orb.local
# - Pod IPs:    Direct connection

# Example: Access a LoadBalancer service
kubectl apply -f deployment.yaml
kubectl expose deploy nginx --type=LoadBalancer --port=80
curl http://nginx.default.svc.cluster.local
# Or: curl http://<service>.k8s.orb.local
```

### Using Local Images

```bash
# Build image (no registry push needed)
docker build -t myapp:latest .

# Use in pod (avoid :latest to prevent pull attempts)
kubectl run myapp --image=myapp:v1

# Or use imagePullPolicy: Never in manifest
```

## Manifests

### Deployment Template

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: myapp
          image: myapp:1.0
          ports:
            - containerPort: 8080
          env:
            - name: ENV_VAR
              value: "value"
          resources:
            requests:
              memory: "64Mi"
              cpu: "250m"
            limits:
              memory: "128Mi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 5
          readinessProbe:
            httpGet:
              path: /ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 3
```

### Service Template

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
  ports:
    - port: 80
      targetPort: 8080
  type: ClusterIP # or NodePort, LoadBalancer
```

## Useful Aliases

```bash
# Add to ~/.bashrc or ~/.zshrc
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deploy'
alias kga='kubectl get all'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ke='kubectl exec -it'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'

# Shell completion
source <(kubectl completion bash)  # or zsh
```

## Deleting Resources

```bash
kubectl delete pod <name>             # Delete pod
kubectl delete deploy <name>          # Delete deployment
kubectl delete svc <name>             # Delete service
kubectl delete -f manifest.yaml       # Delete from file

kubectl delete pods --all             # All pods in namespace
kubectl delete all --all              # All common resources
kubectl delete all -l app=test        # By label

# Force delete stuck pod
kubectl delete pod <name> --force --grace-period=0
```

## See Also

- [Docker](docker.md) — Container basics before orchestration
- [Shell](shell.md) — Scripting for kubectl automation
- [jq](jq.md) — Processing kubectl JSON output
