# Infra
## Configurations for coldwire.org internal infrastructure

### Services
In this folder you will find all files nessesary to deploy the services hosted by coldwire.org

#### Folders hierarchy
- `<service>/build/<image_name>/`: folders with dockerfiles and other necessary resources for building container images
- `<service>/config/`: folder containing configuration files, referenced by deployment file
- `<service>/deploy/`: folder containing the HCL file(s) necessary for deploying the module