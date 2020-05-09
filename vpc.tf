resource "aws_vpc" "COURSE_VPC" {
#resource "aws_vpc" "main" {
cidr_block           = var.vpc_cidr
#cidr_block = "172.19.0.0/16"
enable_dns_hostnames = true
tags = merge(
{
 "Name" = "${local.name_prefix}-VPC"
 #Name = "VPC_name"
},
local.default_tags,
  )
}

resource "aws_internet_gateway" "COURSE_IGW" {
#resource "aws_internet_gateway" "gateway" {
vpc_id = aws_vpc.COURSE_VPC.id
#vpc_id = "${aws_vpc.main.id}"
tags = merge(
  {
   "Name" = "${local.name_prefix}-IGW"
   #Name = "gateway_name"
 },
local.default_tags,
  )
}

resource "aws_subnet" "COURSE_PUBLIC_SUBNET" {
#resource "aws_subnet" "public-subnet" {
  map_public_ip_on_launch = true
  availability_zone       = element(var.az_names, 0)
  #availability_zone = "eu-central-1a"
  vpc_id                  = aws_vpc.COURSE_VPC.id
  #vpc_id          = "${aws_vpc.main.id}"
  cidr_block              = element(var.subnet_cidr_blocks, 0)
  #cidr_block        = "172.19.0.0/21"
  tags = merge(
    {
      "Name" = "${local.name_prefix}-SUBNET-AZ-A"
      #Name = "example_public_subnet"
    },
    local.default_tags,
  )
}

resource "aws_subnet" "COURSE_PRIVATE_SUBNET" {
  map_public_ip_on_launch = false
  availability_zone       = element(var.az_names, 1)
  vpc_id                  = aws_vpc.COURSE_VPC.id
  cidr_block              = element(var.subnet_cidr_blocks, 1)
  tags = merge(
    {
      "Name" = "${local.name_prefix}-SUBNET-AZ-B"
    },
    local.default_tags,
  )
}

resource "aws_eip" "APP_EIP" {
}

resource "aws_nat_gateway" "COURSE_NAT" {
  subnet_id     = aws_subnet.COURSE_PUBLIC_SUBNET.id
  allocation_id = aws_eip.APP_EIP.id
  tags = merge(
    {
      "Name" = "${local.name_prefix}-NGW"
    },
    local.default_tags,
  )
}

resource "aws_route_table" "COURSE_PUBLIC_ROUTE" {
#resource "aws_route_table" "public-routing-table" {
  vpc_id = aws_vpc.COURSE_VPC.id
  #vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.COURSE_IGW.id
    #gateway_id = "${aws_internet_gateway.gateway.id}"
  }

  tags = merge(
    {
      "Name" = "${local.name_prefix}-PUBLIC-RT"
      #Name = "gateway_name"
    },
    local.default_tags,
  )
}

resource "aws_route_table" "COURSE_PRIVATE_ROUTE" {
  vpc_id = aws_vpc.COURSE_VPC.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.COURSE_NAT.id
  }

  tags = merge(
    {
      "Name" = "${local.name_prefix}-PRIVATE-RT"
    },
    local.default_tags,
  )
}

resource "aws_vpc_endpoint" "COURSE_S3_ENDPOINT" {
  vpc_id          = aws_vpc.COURSE_VPC.id
  service_name    = "com.amazonaws.${var.aws_region}.s3"
  route_table_ids = [aws_route_table.COURSE_PUBLIC_ROUTE.id, aws_route_table.COURSE_PRIVATE_ROUTE.id]
}

resource "aws_route_table_association" "PUBLIC_ASSO" {
#resource "aws_route_table_association" "public-route-association" {
  route_table_id = aws_route_table.COURSE_PUBLIC_ROUTE.id
  #route_table_id = "${aws_route_table.public-routing-table.id}"
  subnet_id      = aws_subnet.COURSE_PUBLIC_SUBNET.id
  #subnet_id      = "${aws_subnet.public-subnet.id}"
}

resource "aws_route_table_association" "PRIVATE_ASSO" {
  route_table_id = aws_route_table.COURSE_PRIVATE_ROUTE.id
  subnet_id      = aws_subnet.COURSE_PRIVATE_SUBNET.id
}

resource "aws_network_acl" "COURSE_NACL" {
  vpc_id     = aws_vpc.COURSE_VPC.id
  subnet_ids = [aws_subnet.COURSE_PRIVATE_SUBNET.id, aws_subnet.COURSE_PUBLIC_SUBNET.id]

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 23
    to_port    = 23
  }

  ingress {
    protocol   = "-1"
    rule_no    = 32766
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 23
    to_port    = 23
  }

  egress {
    protocol   = "-1"
    rule_no    = 32766
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(
    {
      "Name" = "${local.name_prefix}-NACL"
    },
    local.default_tags,
  )
}

resource "aws_security_group" "APP_ALB_SG" {
  vpc_id = aws_vpc.COURSE_VPC.id
  name   = "${local.name_prefix}-ALB-SG"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    security_groups = [aws_security_group.APP_SG.id]
  }

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    security_groups = [aws_security_group.APP_SG.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      "Name" = "${local.name_prefix}-SG"
    },
    local.default_tags,
  )
}

resource "aws_security_group" "APP_SG" {
  vpc_id = aws_vpc.COURSE_VPC.id
  name   = "${local.name_prefix}-SG"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [aws_vpc.COURSE_VPC.cidr_block]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = [aws_vpc.COURSE_VPC.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    {
      "Name" = "${local.name_prefix}-SG"
    },
    local.default_tags,
  )
}

resource "aws_security_group" "master_security_group" {
  #emr
  name        = "master_security_group"
  description = "Allow inbound traffic from VPN"
  vpc_id      = aws_vpc.COURSE_VPC.id
 
  # Avoid circular dependencies stopping the destruction of the cluster
  revoke_rules_on_delete = true
 
  # Allow communication between nodes in the VPC
  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    self        = true
  }
 
  ingress {
      from_port   = "8443"
      to_port     = "8443"
      protocol    = "TCP"
  }
 
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  # Allow SSH traffic from VPN
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = [aws_vpc.COURSE_VPC.cidr_block]
  }
 
  #### Expose web interfaces to VPN
 
  # Yarn
  ingress {
    from_port   = 8088
    to_port     = 8088
    protocol    = "TCP"
    cidr_blocks = [aws_vpc.COURSE_VPC.cidr_block] 
  }
 
  # Spark History
  ingress {
      from_port   = 18080
      to_port     = 18080
      protocol    = "TCP"
      cidr_blocks = [aws_vpc.COURSE_VPC.cidr_block]
    }
 
  # Zeppelin
  ingress {
      from_port   = 8890
      to_port     = 8890
      protocol    = "TCP"
      cidr_blocks = [aws_vpc.COURSE_VPC.cidr_block]
  }
 
  # Spark UI
  ingress {
      from_port   = 4040
      to_port     = 4040
      protocol    = "TCP"
      cidr_blocks = [aws_vpc.COURSE_VPC.cidr_block]
  }
 
  # Ganglia
  ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "TCP"
      cidr_blocks = [aws_vpc.COURSE_VPC.cidr_block] 
  }
 
  # Hue
  ingress {
      from_port   = 8888
      to_port     = 8888
      protocol    = "TCP"
      cidr_blocks = [aws_vpc.COURSE_VPC.cidr_block]
  }
 
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    {
      "Name" = "emr_test"
    },
    local.default_tags,
  )
 }

resource "aws_security_group" "slave_security_group" {
  name        = "slave_security_group"
  description = "Allow all internal traffic"
  vpc_id      = aws_vpc.COURSE_VPC.id
  revoke_rules_on_delete = true
 
  # Allow communication between nodes in the VPC
  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    self        = true
  }
 
  ingress {
      from_port   = "8443"
      to_port     = "8443"
      protocol    = "TCP"
  }
 
  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  # Allow SSH traffic from VPN
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = [aws_vpc.COURSE_VPC.cidr_block]
  }
 
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    {
      "Name" = "emr_test"
    },
    local.default_tags,
  )
}