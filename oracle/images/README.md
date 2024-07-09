# Upload images

Create the config file **terraform.tfvars** and add params.
About image_metadata.json https://www.oracle.com/docs/tech/oracle-private-cloud-appliance-x9-2-workload-import.pdf

```hcl
# Body of terraform.tfvars
```

```shell
wget https://factory.talos.dev/image/4a0d65c669d46663f377e7161e50cfd570c401f26fd9e7bda34a0216b6f1922b/v1.7.5/oracle-arm64.raw.xz
https://factory.talos.dev/image/4a0d65c669d46663f377e7161e50cfd570c401f26fd9e7bda34a0216b6f1922b/v1.7.5/oracle-amd64.raw.xz
xz -d oracle-amd64.raw.xz
xz -d oracle-arm64.raw.xz
qemu-img convert -f raw -O qcow2 oracle-arm64.raw oracle-arm64.qcow2
qemu-img convert -f raw -O qcow2 oracle-amd64.raw oracle-amd64.qcow2

cp image_metadata_amd64.json image_metadata.json
tar zcf oracle-amd64.oci oracle-amd64.qcow2 image_metadata.json

cp image_metadata_arm64.json image_metadata.json
tar zcf oracle-arm64.oci oracle-arm64.qcow2 image_metadata.json

terraform init && terraform apply -auto-approve
```
