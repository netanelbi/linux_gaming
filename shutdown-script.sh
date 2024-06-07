#!/bin/bash

# Variables
DISK_NAME="vmdisk"
VM_NAME="vm"
ZONE="me-west1-c"  # Replace with your GCP zone

# Detach the disk from the VM
gcloud compute instances detach-disk $VM_NAME --disk=$DISK_NAME --zone=$ZONE

# Delete the disk
gcloud compute disks delete $DISK_NAME --zone=$ZONE --quiet
