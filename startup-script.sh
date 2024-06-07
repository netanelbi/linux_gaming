#!/bin/bash

# Variables
DISK_NAME="vmdisk"
SNAPSHOT_NAME="vmdisk-snapshot"
DISK_SIZE="100GB"
VM_NAME="vm"
ZONE="me-west1-c"  # Replace with your GCP zone

# Create a new smaller disk from the snapshot
gcloud compute disks create $DISK_NAME --source-snapshot=$SNAPSHOT_NAME --size=$DISK_SIZE --zone=$ZONE

# Attach the new smaller disk to the VM
gcloud compute instances attach-disk $VM_NAME --disk=$DISK_NAME --zone=$ZONE

# Optionally, resize the filesystem on the new disk (assuming ext4 and /dev/sdb)
# Mount the disk and resize the filesystem
sudo mkdir -p /mnt/$DISK_NAME
sudo mount /dev/sdb /mnt/$DISK_NAME
sudo resize2fs /dev/sdb
