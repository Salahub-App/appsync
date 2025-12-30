###############################################################################
# VPC Peering - Bahrain to Virginia
###############################################################################

# VPC Peering Connection Request (Bahrain as requester)
resource "aws_vpc_peering_connection" "bahrain_to_virginia" {
  vpc_id        = aws_vpc.main.id
  peer_vpc_id   = var.virginia_vpc_id
  peer_region   = "us-east-1"
  auto_accept   = false # Cross-region peering cannot auto-accept

  tags = merge(var.tags, {
    Name = "${var.project_name}-peering-bahrain-virginia"
    Side = "Requester"
  })
}

# Accept VPC Peering in Virginia
resource "aws_vpc_peering_connection_accepter" "virginia_accept" {
  provider                  = aws.virginia
  vpc_peering_connection_id = aws_vpc_peering_connection.bahrain_to_virginia.id
  auto_accept               = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-peering-bahrain-virginia"
    Side = "Accepter"
  })
}

###############################################################################
# Route Updates - Bahrain Side
###############################################################################

# Route from Bahrain private subnets to Virginia VPC
resource "aws_route" "bahrain_to_virginia" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = var.virginia_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.bahrain_to_virginia.id

  depends_on = [aws_vpc_peering_connection_accepter.virginia_accept]
}

# Route from Bahrain public subnets to Virginia VPC (optional, for troubleshooting)
resource "aws_route" "bahrain_public_to_virginia" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = var.virginia_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.bahrain_to_virginia.id

  depends_on = [aws_vpc_peering_connection_accepter.virginia_accept]
}

###############################################################################
# Route Updates - Virginia Side
###############################################################################

# Get Virginia default VPC main route table
data "aws_route_table" "virginia_main" {
  provider = aws.virginia
  vpc_id   = var.virginia_vpc_id

  filter {
    name   = "association.main"
    values = ["true"]
  }
}

# Route from Virginia to Bahrain VPC
resource "aws_route" "virginia_to_bahrain" {
  provider                  = aws.virginia
  route_table_id            = data.aws_route_table.virginia_main.id
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.bahrain_to_virginia.id

  depends_on = [aws_vpc_peering_connection_accepter.virginia_accept]
}
