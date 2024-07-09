
# openssl genrsa -out ~/.oci/oci_api_key.pem 2048
# chmod go-rwx ~/.oci/oci_api_key.pem
# openssl rsa -pubout -in ~/.oci/oci_api_key.pem -out ~/.oci/oci_api_key_public.pem

provider "oci" {
  config_file_profile = "DEFAULT"
  auth             = "SecurityToken"
}