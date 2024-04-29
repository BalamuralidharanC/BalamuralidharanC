#!/bin/bash

# Define the namespace and deployment name
NAMESPACE="vote"
DEPLOYMENT_NAME="vote"

# Define the parent directory to save logs
PARENT_LOG_DIR="/mnt/c/Users/BalamuralidharanChak/test"

# Create parent log directory if it doesn't exist
mkdir -p "$PARENT_LOG_DIR"
echo "Parent log directory created: $PARENT_LOG_DIR" 

# Get current timestamp
CURRENT_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
echo "Current timestamp: $CURRENT_TIME" 

# Create a directory with the current timestamp as its name
LOG_DIR="$PARENT_LOG_DIR/$CURRENT_TIME"
echo "Log directory created: $LOG_DIR" 

# Create log directory
mkdir -p "$LOG_DIR"
echo "Created log directory: $LOG_DIR" 

# Duration to capture logs (in seconds)
DURATION=$((2*60))  # 2 minutes
echo "Duration to capture logs set to: $DURATION seconds" 

# Get pods associated with the deployment
echo "Getting pods associated with the deployment..." 
PODS=$(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}')
echo "Pods associated within the namespace: $PODS" 

# Capture all events
echo "Capturing all events..." 
kubectl get events -n "$NAMESPACE" --sort-by='.metadata.creationTimestamp' --field-selector="type!=Normal" > "$LOG_DIR/all-events.log"
echo "All events captured and saved to: $LOG_DIR/all-events.log" 

# Iterate over each pod
for POD_NAME in $PODS; do
    echo "Processing pod: $POD_NAME" 

    # Describe the pod and save output
    echo "Describing pod: $POD_NAME..." 
    kubectl describe pod -n "$NAMESPACE" "$POD_NAME" > "$LOG_DIR/$POD_NAME-describe.log" &
    echo "Pod described and output saved to: $LOG_DIR/$POD_NAME-describe.log" 

    # Get node name associated with the pod
    NODE_NAME=$(kubectl get pod -n "$NAMESPACE" "$POD_NAME" -o jsonpath='{.spec.nodeName}')

    # Describe node and save output
    echo "Describing node: $NODE_NAME..." 
    kubectl describe node "$NODE_NAME" > "$LOG_DIR/node-$NODE_NAME-describe.log" &
    echo "Node described and output saved to: $LOG_DIR/node-$NODE_NAME-describe.log" 

    # Capture HPA events for the current pod
    echo "Capturing HPA events for pod: $POD_NAME..." 
    kubectl get events -n "$NAMESPACE" --sort-by='.metadata.creationTimestamp' --field-selector="involvedObject.kind=HorizontalPodAutoscaler,type!=Normal,involvedObject.name=$POD_NAME" > "$LOG_DIR/hpa-events-$POD_NAME.log" &
    echo "HPA events captured and saved to: $LOG_DIR/hpa-events-$POD_NAME.log" 

    # Capture logs for each container within the pod with flags -f, --since, --timestamps
    CONTAINER_NAMES=$(kubectl get pod "$POD_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.containers[*].name}')
    for CONTAINER_NAME in $CONTAINER_NAMES; do
        # Capture logs for each container
        echo "Capturing logs for container $CONTAINER_NAME in pod $POD_NAME..." 
        kubectl logs -n "$NAMESPACE" "$POD_NAME" -c "$CONTAINER_NAME" -f --since="$DURATION"s --timestamps > "$LOG_DIR/$POD_NAME-$CONTAINER_NAME.log" &
        echo "Logs captured for container $CONTAINER_NAME in pod $POD_NAME and saved to: $LOG_DIR/$POD_NAME-$CONTAINER_NAME.log" 
    done

    # Exec into the pod and collect ps -ef output
    echo "Executing 'ps -ef' in pod $POD_NAME..." 
    kubectl exec -n "$NAMESPACE" "$POD_NAME" -- ps -ef > "$LOG_DIR/$POD_NAME-ps-ef.log" &
    echo "'ps -ef' output collected from pod $POD_NAME and saved to: $LOG_DIR/$POD_NAME-ps-ef.log" 

    # Check if the application is Java-based and execute heap dump if true
    if kubectl exec -n "$NAMESPACE" "$POD_NAME" -- ps -ef | grep java; then
        echo "Java application detected in pod $POD_NAME. Collecting Java heap dump..." 
        kubectl exec -n "$NAMESPACE" "$POD_NAME" -- jcmd 1 GC.heap_dump "$LOG_DIR/$POD_NAME-java-heapdump.hprof" &
        echo "Java heap dump collected from pod $POD_NAME and saved to: $LOG_DIR/$POD_NAME-java-heapdump.hprof" 
    else
        echo "No Java application detected in pod $POD_NAME. Skipping heap dump collection." 
    fi
done

# Wait for all background processes to finish
echo "Waiting for all background processes to finish..." 
wait 

echo "Logs captured for 2 minutes with flags -f, --since, --timestamps and saved to $LOG_DIR"
