
# create oci vcn with internet gateway, nat gateway, and service gateway

resource "oci_core_vcn" "vnet" {
  compartment_id = var.compartment_id
  display_name   = "${var.name}-vcn"
  dns_label      = var.name
  cidr_blocks    = var.cidr_blocks
  freeform_tags  = var.freeform_tags
  defined_tags   = var.defined_tags
}

resource "oci_core_internet_gateway" "ig" {
  compartment_id = var.compartment_id
  display_name   = "Internet Gateway"
  vcn_id         = oci_core_vcn.vnet.id
  freeform_tags  = var.freeform_tags
  defined_tags   = var.defined_tags
}

data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All [A-Z]{3} Services In Oracle Services Network"]
    regex  = true
  }
}

data "oci_core_services" "object_storage" {
  filter {
    name   = "name"
    values = ["OCI [A-Z]{3} Object Storage"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "sg" {
  compartment_id = var.compartment_id
  display_name   = "Service Gateway"
  vcn_id         = oci_core_vcn.vnet.id

  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }
  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_nat_gateway" "nat" {
  compartment_id = var.compartment_id
  display_name   = "NAT Gateway"
  vcn_id         = oci_core_vcn.vnet.id
  freeform_tags  = var.freeform_tags
  defined_tags   = var.defined_tags
}

resource "oci_core_default_security_list" "security_list" {
  manage_default_resource_id = oci_core_vcn.vnet.default_security_list_id

  egress_security_rules {
    description = "Allow all egress"
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    description = "Allow all within VCN"
    protocol    = "all"
    source      = oci_core_vcn.vnet.cidr_block
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_default_route_table" "default" {
  manage_default_resource_id = oci_core_vcn.vnet.default_route_table_id
  display_name               = "Default Route Table for ${var.name}"

  route_rules {
    network_entity_id = oci_core_internet_gateway.ig.id
    description       = "Public Internet through Internet Gateway"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }

  route_rules {
    network_entity_id = oci_core_service_gateway.sg.id
    description       = "Object Storage through Service Gateway"
    destination       = data.oci_core_services.object_storage.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
  }
}

resource "oci_core_route_table" "nat" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.vnet.id

  display_name = "NAT and Service Gateway"
  route_rules {
    network_entity_id = oci_core_nat_gateway.nat.id
    description       = "Public Internet through NAT Gateway"
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }

  route_rules {
    network_entity_id = oci_core_service_gateway.sg.id
    description       = "All Regional Services through Service Gateway"
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
  }
}
