# OpenWebUI Deployment on ThreeFold Grid

## Overview

This script automates the deployment of an OpenWebUI instance on the ThreeFold Grid using the `tfgrid3deployer` module. It sets up a virtual machine (VM), configures networking, and assigns a webname for easy access.

## Requirements

- V compiler installed
- OpenSSL support enabled
- herolib dependencies:
  - `incubaid.herolib.threefold.grid3.gridproxy`
  - `incubaid.herolib.threefold.grid3.deployer`
  - `incubaid.herolib.installers.threefold.griddriver`

## Installation

Ensure you have the required dependencies installed. The script will automatically install the `griddriver` before proceeding.

## Usage

Run the script using the following command:

```sh
./open_webui_gw.vsh
```

### Script Execution Steps

1. Installs the necessary ThreeFold Grid driver.
2. Retrieves credentials for deployment.
3. Creates a new deployment named `openwebui_example`.
4. Adds a VM with the following specifications:
   - 1 CPU
   - 16GB RAM
   - 100GB storage
   - Uses planetary networking
   - Deploys OpenWebUI from the ThreeFold Hub.
5. Deploys the VM.
6. Retrieves VM information.
7. Configures a webname (`openwebui`) pointing to the VM's backend.
8. Deploys the webname for public access.
9. Retrieves and displays webname gateway details.

## Cleanup

To delete the deployment, run the following line in the script:

```v
tfgrid3deployer.delete_deployment(deployment_name)!
```

## Gateway Information

The gateway points to the WireGuard IP of the VM on port 8080, which is the port that the OpenWebUI server is listening on.

## Notes

- Ensure you have a valid ThreeFold Grid account and necessary permissions to deploy resources.
- Adjust VM specifications based on your requirements.
