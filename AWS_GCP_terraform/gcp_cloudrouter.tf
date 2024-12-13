resource "google_compute_router" "router" {
  name = "ha-vpn-router"
  network = google_compute_network.vpc_network.id
  bgp {
    asn = 65000
  }
}

resource "google_compute_ha_vpn_gateway" "ha-gateway" {
  name = "ha-vpn"
  network = google_compute_network.vpc_network.id
}

resource "google_compute_external_vpn_gateway" "peer-gw" {
  name = "peer-gw"
  redundancy_type = "FOUR_IPS_REDUNDANCY"
  interface {
    id = 0
    ip_address = aws_vpn_connection.AWS-GCP-VPN-0.tunnel1_address
  }
  interface {
    id = 1
    ip_address = aws_vpn_connection.AWS-GCP-VPN-0.tunnel2_address
  }
  interface {
    id = 2
    ip_address = aws_vpn_connection.AWS-GCP-VPN-1.tunnel1_address
  }
  interface {
    id = 3
    ip_address = aws_vpn_connection.AWS-GCP-VPN-1.tunnel2_address
  }
}

resource "google_compute_vpn_tunnel" "tunnel1" {
  name = "nat-vpn-tunnel1"
  vpn_gateway = google_compute_ha_vpn_gateway.ha-gateway.id
  peer_external_gateway = google_compute_external_vpn_gateway.peer-gw.id
  peer_external_gateway_interface = 0
  shared_secret = aws_vpn_connection.AWS-GCP-VPN-0.tunnel1_preshared_key
  router = google_compute_router.router.id
  vpn_gateway_interface = 0
}

resource "google_compute_vpn_tunnel" "tunnel2" {
  name = "ha-vpn-tunnel2"
  vpn_gateway = google_compute_ha_vpn_gateway.ha-gateway.id
  peer_external_gateway = google_compute_external_vpn_gateway.peer-gw.id
  peer_external_gateway_interface = 1
  shared_secret = aws_vpn_connection.AWS-GCP-VPN-0.tunnel2_preshared_key
  router = "${google_compute_router.router.id}"
  vpn_gateway_interface = 0
}

resource "google_compute_vpn_tunnel" "tunnel3" {
  name = "ha-vpn-tunnel3"
  vpn_gateway = google_compute_ha_vpn_gateway.ha-gateway.id
  peer_external_gateway = google_compute_external_vpn_gateway.peer-gw.id
  peer_external_gateway_interface = 2
  shared_secret = aws_vpn_connection.AWS-GCP-VPN-1.tunnel1_preshared_key
  router = "${google_compute_router.router.id}"
  vpn_gateway_interface = 1
}

resource "google_compute_vpn_tunnel" "tunnel4" {
  name = "ha-vpn-tunnel4"
  vpn_gateway = google_compute_ha_vpn_gateway.ha-gateway.id
  peer_external_gateway = google_compute_external_vpn_gateway.peer-gw.id
  peer_external_gateway_interface = 3
  shared_secret = aws_vpn_connection.AWS-GCP-VPN-1.tunnel2_preshared_key
  router = "${google_compute_router.router.id}"
  vpn_gateway_interface = 1
}

resource "google_compute_router_interface" "router-interface1" {
  name = "router-interface1"
  router = google_compute_router.router.name
  vpn_tunnel = google_compute_vpn_tunnel.tunnel1.name
}

resource "google_compute_router_peer" "route-peer1" {
  name = "route-peer1"
  router = google_compute_router.router.name
  ip_address = aws_vpn_connection.AWS-GCP-VPN-0.tunnel1_cgw_inside_address
  peer_ip_address = aws_vpn_connection.AWS-GCP-VPN-0.tunnel1_vgw_inside_address
  peer_asn = 64512
  interface = google_compute_router_interface.router-interface1.name
}

resource "google_compute_router_interface" "router-interface2" {
  name = "router-interface2"
  router = google_compute_router.router.name
  vpn_tunnel = google_compute_vpn_tunnel.tunnel2.name
}

resource "google_compute_router_peer" "route-peer2" {
  name = "route-peer2"
  router = google_compute_router.router.name
  ip_address = aws_vpn_connection.AWS-GCP-VPN-0.tunnel2_cgw_inside_address
  peer_ip_address = aws_vpn_connection.AWS-GCP-VPN-0.tunnel2_vgw_inside_address
  peer_asn = 64512
  interface = google_compute_router_interface.router-interface2.name
}

resource "google_compute_router_interface" "router-interface3" {
  name = "route-interface3"
  router = google_compute_router.router.name
  vpn_tunnel = google_compute_vpn_tunnel.tunnel3.name
}

resource "google_compute_router_peer" "route-peer3" {
  name = "route-peer3"
  router = google_compute_router.router.name
  ip_address = aws_vpn_connection.AWS-GCP-VPN-1.tunnel1_cgw_inside_address
  peer_ip_address = aws_vpn_connection.AWS-GCP-VPN-1.tunnel1_vgw_inside_address
  peer_asn = 64512
  interface = google_compute_router_interface.router-interface3.name
}

resource "google_compute_router_interface" "router-interface4" {
  name = "route-interface4"
  router = google_compute_router.router.name
  vpn_tunnel = google_compute_vpn_tunnel.tunnel4.name
}

resource "google_compute_router_peer" "route-peer4" {
  name = "route-peer4"
  router = google_compute_router.router.name
  ip_address = aws_vpn_connection.AWS-GCP-VPN-1.tunnel2_cgw_inside_address
  peer_ip_address = aws_vpn_connection.AWS-GCP-VPN-1.tunnel2_vgw_inside_address
  peer_asn = 64512
  interface = google_compute_router_interface.router-interface4.name
}
