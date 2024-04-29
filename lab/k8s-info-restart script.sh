#!/bin/bash

# Set variables
AKS_RESOURCE_GROUP="your-resource-group"
AKS_CLUSTER_NAME="your-aks-cluster"

# Function to gather information about pods
get_pod_info() {
    echo "========================="
    echo "Pod Information:"
    echo "========================="
    kubectl get pods --all-namespaces
}

# Function to gather information about namespaces
get_namespace_info() {
    echo "========================="
    echo "Namespace Information:"
    echo "========================="
    kubectl get namespaces
}

# Function to gather information about Horizontal Pod Autoscalers (HPA)
get_hpa_info() {
    echo "========================="
    echo "Horizontal Pod Autoscaler (HPA) Information:"
    echo "========================="
    kubectl get hpa --all-namespaces
}

# Function to gather information about Pod Disruption Budgets (PDB)
get_pdb_info() {
    echo "========================="
    echo "Pod Disruption Budget (PDB) Information:"
    echo "========================="
    kubectl get pdb --all-namespaces
}

# Function to gather information about DaemonSets
get_daemonset_info() {
    echo "========================="
    echo "DaemonSet Information:"
    echo "========================="
    kubectl get daemonset --all-namespaces
}

# Function to gather information about Jobs
get_job_info() {
    echo "========================="
    echo "Job Information:"
    echo "========================="
    kubectl get jobs --all-namespaces
}

# Main function to gather all information
get_all_info() {
    get_pod_info
    get_namespace_info
    get_hpa_info
    get_pdb_info
    get_daemonset_info
    get_job_info
}

# Execute main function
get_all_info
