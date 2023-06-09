
# create a subnet with a dedicated security list

resource "oci_core_subnet" "subnet" {
  display_name               = "${var.name}-subnet"
  dns_label                  = var.name
  compartment_id             = var.compartment_id
  vcn_id                     = var.vcn_id
  cidr_block                 = var.cidr_block
  route_table_id             = var.route_table_id
  prohibit_public_ip_on_vnic = var.private_subnet
  security_list_ids          = var.security_list_ids
}
