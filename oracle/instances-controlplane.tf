
data "oci_core_vnic_attachments" "contolplane" {
  count          = lookup(var.controlplane, "count", 0)
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.contolplane[count.index].id
}

resource "oci_core_ipv6" "contolplane" {
  count   = lookup(var.controlplane, "count", 0)
  vnic_id = data.oci_core_vnic_attachments.contolplane[count.index].vnic_attachments[0]["vnic_id"]
}

locals {
  oci = templatefile("${path.module}/templates/oci.ini", {
    compartment_id = var.compartment_ocid
    region         = var.region
  })
}

resource "oci_core_instance" "contolplane" {
  count = lookup(var.controlplane, "count", 0)

  compartment_id      = var.compartment_ocid
  display_name        = "${local.project}-contolplane-${count.index + 1}"
  defined_tags        = merge(var.tags, { "Kubernetes.Type" = "infra", "Kubernetes.Role" = "contolplane" })
  availability_domain = local.zones[count.index % local.zone_count]
  fault_domain        = element(data.oci_identity_fault_domains.domains[element(local.zones, count.index)].fault_domains, floor(count.index / local.zone_count)).name

  shape = lookup(var.controlplane, "type", "VM.Standard.A1.Flex")
  shape_config {
    ocpus         = lookup(var.controlplane, "ocpus", 1)
    memory_in_gbs = lookup(var.controlplane, "memgb", 3)
  }

  metadata = {
    user_data = base64encode(templatefile("${path.module}/templates/controlplane.yaml",
      merge(var.kubernetes, {
        name        = "${local.project}-contolplane-${count.index + 1}"
        lbv4        = local.lbv4
        lbv4_local  = local.lbv4_local
        nodeSubnets = local.network_public[element(local.zones, count.index)].cidr_block
        ccm         = filebase64("${path.module}/templates/oci-cloud-provider.yaml")
        oci         = base64encode(local.oci)
      })
    ))
  }

  source_details {
    source_type             = "image"
    source_id               = lookup(var.controlplane, "type", "VM.Standard.A1.Flex") == "VM.Standard.A1.Flex" ? data.oci_core_images.talos_arm.images[0].id : data.oci_core_images.talos_arm.images[0].id
    # boot_volume_size_in_gbs = "50"
  }
  create_vnic_details {
    assign_public_ip = true
    subnet_id        = local.network_public[element(local.zones, count.index)].id
    private_ip       = cidrhost(local.network_public[element(local.zones, count.index)].cidr_block, 11 + floor(count.index / local.zone_count))
    nsg_ids          = [local.nsg_talos, local.nsg_cilium, local.nsg_contolplane]
  }

  agent_config {
    are_all_plugins_disabled = true
    is_management_disabled   = true
    is_monitoring_disabled   = true
  }
  availability_config {
    is_live_migration_preferred = true
    recovery_action             = "RESTORE_INSTANCE"
  }
  launch_options {
    firmware                = "UEFI_64"
    boot_volume_type        = "PARAVIRTUALIZED"
    remote_data_volume_type = "PARAVIRTUALIZED"
    network_type            = "PARAVIRTUALIZED"
  }
  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }

  timeouts {
    create = "10m"
  }

  lifecycle {
    ignore_changes = [
      fault_domain,
      shape_config,
      defined_tags,
      create_vnic_details["defined_tags"],
      launch_options["is_pv_encryption_in_transit_enabled"],
      metadata
    ]
  }
}

resource "oci_network_load_balancer_backend" "contolplane" {
  count                    = local.lbv4_enable ? lookup(var.controlplane, "count", 0) : 0
  backend_set_name         = oci_network_load_balancer_backend_set.contolplane[0].name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.contolplane[0].id
  port                     = 6443

  name      = "${local.project}-contolplane-${count.index + 1}"
  target_id = oci_core_instance.contolplane[count.index].id
}

resource "oci_network_load_balancer_backend" "contolplane_talos" {
  count                    = local.lbv4_enable ? lookup(var.controlplane, "count", 0) : 0
  backend_set_name         = oci_network_load_balancer_backend_set.contolplane_talos[0].name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.contolplane[0].id
  port                     = 50000

  name      = "${local.project}-contolplane-talos-${count.index + 1}"
  target_id = oci_core_instance.contolplane[count.index].id
}
