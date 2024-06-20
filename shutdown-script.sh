#!/bin/bash
echo "shutdown started ***"

# Variables
DISK_NAME="vmdisk"
VM_NAME="vm"
ZONE="me-west1-c"  # Replace with your GCP zone
sudo umount /mnt/$DISK_NAME
# Detach the disk from the VM
echo "Detaching disk $DISK_NAME from $VM_NAME"
gcloud compute instances detach-disk $VM_NAME --disk=$DISK_NAME --zone=$ZONE
if [ $? -eq 0 ]; then
    echo "Successfully detached disk $DISK_NAME"
    # Introduce a delay to ensure detachment is complete
    sleep 5

    # Delete the disk
    echo "Deleting disk $DISK_NAME"
    gcloud compute disks delete $DISK_NAME --zone=$ZONE --quiet
    if [ $? -eq 0 ]; then
        echo "Successfully deleted disk $DISK_NAME"
    else
        echo "Failed to delete disk $DISK_NAME"
    fi
else
    echo "Failed to detach disk $DISK_NAME"
fi

echo "shutdown successful"