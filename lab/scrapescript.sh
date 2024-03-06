#!/bin/bash

# Define the namespace and deployment name
NAMESPACE="bala"
DEPLOYMENT_NAME="two-container-deployment"

# Define the parent directory to save logs
PARENT_LOG_DIR="/mnt/d/bala-works/logs/minikubelogs"

# Create parent log directory if it doesn't exist
mkdir -p "$PARENT_LOG_DIR"

# Get current timestamp
CURRENT_TIME=$(date +"%Y-%m-%d_%H-%M-%S")

# Create a directory with the current timestamp as its name
LOG_DIR="$PARENT_LOG_DIR/$CURRENT_TIME"

# Create log directory
mkdir -p "$LOG_DIR"

# Duration to capture logs (in seconds)
DURATION=$((2*60))  # 2 minutes

# Get pods associated with the deployment
PODS=$(kubectl get pods -n "$NAMESPACE" -l app="$DEPLOYMENT_NAME" -o jsonpath='{.items[*].metadata.name}')

# Capture all events
kubectl get events -n "$NAMESPACE" --sort-by='.metadata.creationTimestamp' --field-selector="type!=Normal" > "$LOG_DIR/all-events.log"

# Iterate over each pod
for POD_NAME in $PODS; do
    # Describe the pod and save output
    kubectl describe pod -n "$NAMESPACE" "$POD_NAME" > "$LOG_DIR/$POD_NAME-describe.log" &

    # Get node name associated with the pod
    NODE_NAME=$(kubectl get pod -n "$NAMESPACE" "$POD_NAME" -o jsonpath='{.spec.nodeName}')

    # Describe node and save output
    kubectl describe node "$NODE_NAME" > "$LOG_DIR/node-$NODE_NAME-describe.log" &

    # Capture HPA events for the current pod
    kubectl get events -n "$NAMESPACE" --sort-by='.metadata.creationTimestamp' --field-selector="involvedObject.kind=HorizontalPodAutoscaler,type!=Normal,involvedObject.name=$POD_NAME" > "$LOG_DIR/hpa-events-$POD_NAME.log" &

    # Capture logs for each container within the pod with flags -f, --since, --timestamps
    CONTAINER_NAMES=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.containers[*].name}')
    for CONTAINER_NAME in $CONTAINER_NAMES; do
        # Capture logs for each container
        kubectl logs -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER_NAME" -f --since="$DURATION" --timestamps > "$LOG_DIR/$POD_NAME-$CONTAINER_NAME.log" &
    done

    # Exec into the pod and collect top output
    timeout "$DURATION" kubectl exec -n "$NAMESPACE" "$POD_NAME" -- top -n 1 > "$LOG_DIR/$POD_NAME-top.log" &
done

# Wait for all background processes to finish
wait

echo "Logs captured for 2 minutes with flags -f, --since, --timestamps and saved to $LOG_DIR"
