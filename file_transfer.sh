#!/bin/bash

# Function to display an error message and exit
error_exit() {
  echo "$1" 1>&2
  exit 1
}

# Function to find the SSH key pair file
find_key_pair_file() {
  local search_dir="$1"
  local key_name="$2"

  find "$search_dir" -type f -name "$key_name" 2>/dev/null
}


# Function to perform SCP file transfer
perform_scp() {
  local direction="$1"
  local local_path="$2"
  local remote_path="$3"
  local ec2_ip="$4"
  local key_path="$5"
  local username="$6"

  if [[ "$direction" == "upload" ]]; then
    echo "Uploading $local_path to $username@$ec2_ip:$remote_path..."
    scp -i "$key_path" "$local_path" "$username@$ec2_ip:$remote_path"
  elif [[ "$direction" == "download" ]]; then
    echo "Downloading $username@$ec2_ip:$remote_path to $local_path..."
    scp -i "$key_path" "$username@$ec2_ip:$remote_path" "$local_path"
  fi

  
# Prompt user for the public IP address of the EC2 instance
read -p "Enter the public IP address of the EC2 instance: " ec2_ip

# Ask the user whether to search for the SSH key pair file automatically or provide the path manually
read -p "Do you want to search for the SSH key pair file automatically? (yes/no): " auto_search

if [[ "$auto_search" == "yes" ]]; then
  # Prompt user for the directory to search for the SSH key pair file
  read -p "Enter the directory to search for the SSH key pair file (e.g., /path/to/search): " search_dir
  [ -z "$search_dir" ] && error_exit "Error: Directory to search cannot be empty."

  # Prompt user for the name of the SSH key pair file
  read -p "Enter the name of the SSH key pair file (e.g., keypair.pem): " key_name
  [ -z "$key_name" ] && error_exit "Error: Key pair file name cannot be empty."

  # Search for the SSH key pair file
  key_path=$(find_key_pair_file "$search_dir" "$key_name")

  # Check if the key file was found
  if [ -z "$key_path" ]; then
    error_exit "Error: SSH key file not found in $search_dir"
  fi

  echo "Found SSH key file at: $key_path"

else
  # Prompt user for the path to the SSH key pair file directly
  read -p "Enter the path to the SSH key pair file (e.g., /path/to/keypair.pem): " key_path
  [ -z "$key_path" ] && error_exit "Error: Path to SSH key pair file cannot be empty."

  # Check if the SSH key file exists
  if [ ! -f "$key_path" ]; then
    error_exit "Error: SSH key file not found at $key_path"
  fi
fi

# Prompt user for the username for the EC2 instance
read -p "Enter the username for the EC2 instance (e.g., ubuntu): " username
[ -z "$username" ] && error_exit "Error: Username cannot be empty."

# Prompt user for the type of operation (upload or download)
read -p "Do you want to upload or download a file? (upload/download): " operation
[[ "$operation" != "upload" && "$operation" != "download" ]] && error_exit "Error: Invalid operation. Use 'upload' or 'download'."

# Prompt user for local and remote paths based on the operation
if [[ "$operation" == "upload" ]]; then
  read -p "Enter the path to the local file you want to upload: " local_path
  

  read -p "Enter the remote path on the EC2 instance where the file should be uploaded: " remote_path
  
  perform_scp "upload" "$local_path" "$remote_path" "$ec2_ip" "$key_path" "$username"

elif [[ "$operation" == "download" ]]; then
  read -p "Enter the remote path on the EC2 instance from where the file should be downloaded: " remote_path
  
  read -p "Enter the local path where the file should be downloaded: " local_path
  
  perform_scp "download" "$local_path" "$remote_path" "$ec2_ip" "$key_path" "$username"
fi

