#!/bin/bash

# This script prepares a new machine for setup by copying necessary SSH configuration files and keys,
# and setting up a project directory with a Git repository on the remote machine.

# Function to print an error message and exit the script
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

# Function to display the help message
display_help() {
    cat << EOF
Usage: $(basename "$0") [OPTION]

This script prepares a new machine for setup by copying SSH configuration files and keys,
and setting up a project directory with a Git repository on the remote machine.

Options:
  -h, --help    Display this help message and exit.
  -i, --info    Display detailed information about this script.

If no options are provided, the script will prompt you to confirm if the new machine has been added to your SSH config file.

Examples:
  $(basename "$0")          # Run the script normally.
  $(basename "$0") --help   # Display the help message.
  $(basename "$0") --info   # Display detailed information.

EOF
}

# Function to display script information
display_info() {
    cat << EOF
Script Information:

- This script is designed to automate the preparation of a new machine for setup.
- It assumes that you have already configured SSH access by adding the new machine to your SSH config file.
- The script will prompt you to confirm this before proceeding with the setup.
- If you haven't added the machine, the script will exit with an error message, instructing you to do so.

This script follows best practices in Linux shell scripting, ensuring portability, error handling, and input validation.

EOF
}

# Check for options and handle them
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            display_help
            exit 0
            ;;
        -i|--info)
            display_info
            exit 0
            ;;
        *)
            error_exit "Unknown option: $1. Use --help for usage information."
            ;;
    esac
    shift
done

# Prompt user to confirm if they have added the new machine to the SSH config
read -r -p "Have you added the new machine to your SSH config file? (y/n): " response

# Convert the response to lowercase for consistency
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

# Validate user response and proceed accordingly
case "$response" in
    y|yes)
        # Ask for the SSH alias if the user confirmed
        read -r -p "Please enter the SSH alias for the new machine: " ssh_alias
        echo "SSH alias '$ssh_alias' has been saved."
        ;;
    n|no)
        error_exit "Please add the new machine to your SSH config file before running this script."
        ;;
    *)
        error_exit "Invalid input. Please enter 'y' or 'n'."
        ;;
esac

# Use rsync to copy the .ssh config file and specified files to the remote machine
rsync -av ~/.ssh/config ~/.ssh/oc_gh ~/.ssh/oc-advai-gh ~/.ssh/hyperstack-trial-ssh_hyperstack.txt "$ssh_alias":~/.ssh/

# Provide feedback on the rsync operation
if [[ $? -eq 0 ]]; then
    echo "Files have been successfully copied to the remote machine."
else
    error_exit "Failed to copy files to the remote machine."
fi

# Run remote commands to create the ~/projects directory and clone the Git repository
ssh "$ssh_alias" << 'EOF'
    mkdir -p ~/projects
    git clone git@github.com-personal:Oliver-Chalkley/debian_based_general_setup.git ~/projects/debian_based_general_setup
EOF

# Check the exit status of the SSH command
if [[ $? -eq 0 ]]; then
    echo "Directory created and repository cloned successfully on the remote machine."
else
    error_exit "Failed to execute remote commands on the remote machine."
fi
