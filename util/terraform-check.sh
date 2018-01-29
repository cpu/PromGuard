#!/bin/bash

# Set errexit option to exit immediately on any non-zero status return.
set -e

# check_ansible checks that Terraform is installed on the local system
# and that it is a supported version.
function check_terraform() {
  local REQUIRED_TERRAFORM_VERSION="0.11.0"

  if ! command -v terraform > /dev/null 2>&1; then
    echo "
This project requires Terraform and it is not installed.
Please see the README Installation section on Prerequisites"
    exit 1
  fi

  if [[ $(terraform --version | grep -oe 'v0\(.[0-9]\)*') < $REQUIRED_TERRAFORM_VERSION ]]; then
      echo "
This project requires Terraform version $REQUIRED_TERRAFORM_VERSION or higher.
This system has $(terraform --version)."
      exit 1
  fi
}
