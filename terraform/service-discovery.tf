resource "aws_service_discovery_private_dns_namespace" "discovery" {
  name = "sample.tf"
  vpc  = aws_vpc.vpc.id
}
