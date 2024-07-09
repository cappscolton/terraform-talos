
# openssl genrsa -out ~/.oci/oci_main_terraform.pem 2048
# chmod go-rwx ~/.oci/oci_main_terraform.pem
# openssl rsa -pubout -in ~/.oci/oci_main_terraform.pem -out ~/.oci/oci_main_terraform_public.pem

provider "oci" {
  config_file_profile = "DEFAULT"
  auth             = "SecurityToken"
}