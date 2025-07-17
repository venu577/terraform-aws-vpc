#roboshop-dev
resource "aws_vpc" "main" {
    cidr_block = var.cidr_block
    instance_tenancy = "default"
    enable_dns_hostnames = "true"

    tags = merge(
        var.vpc_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}"
        }
    )
}

#IGW(internet Gateway)
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id # Attach the IGW to the VPC
    tags = merge(
        var.igw_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}"
        }
    )
}

#roboshop-dev-public-us-east-1a
#roboshop-dev-public-us-east-1b
resource "aws_subnet" "public" {
    count = length(var.public_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.public_subnet_cidrs[count.index]
    availability_zone = local.az_names[count.index]
    map_public_ip_on_launch = true

    tags = merge(
        var.public_subnet_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-public-${local.az_names[count.index]}"
        }
    )
}

#roboshop-dev-private-us-east-1a
#roboshop-dev-private-us-east-1b
resource "aws_subnet" "private" {
    count = length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.private_subnet_cidrs[count.index]
    availability_zone = local.az_names[count.index]
    
    tags = merge(
        var.private_subnet_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-private-${local.az_names[count.index]}"
        }
    )
}

#roboshop-dev-database-us-east-1a
#roboshop-dev-database-us-east-1b
resource "aws_subnet" "database" {
    count = length(var.database_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = var.database_subnet_cidrs[count.index]
    availability_zone = local.az_names[count.index]
    
    tags = merge(
        var.database_subnet_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-database-${local.az_names[count.index]}"
        }
    )
}

#elastic IP for NAT Gateway
resource "aws_eip" "nat" {
    domain = "vpc"
    tags = merge(
        var.eip_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}"
        }
    )
}

#NAT Gateway
resource "aws_nat_gateway" "main" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public[0].id # Use the first public subnet for the NAT Gateway

    tags = merge(
        var.nat_gateway_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}"
        }
    )
    depends_on = [aws_internet_gateway.main] # Ensure the IGW is created before the NAT Gateway
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    tags = merge (
        var.public_route_table_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-public"
        }
    )
}

# Route Table for Private Subnets
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id
    tags = merge (
        var.private_route_table_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-private"
        }
    )
}

# Route Table for database Subnets
resource "aws_route_table" "database" {
    vpc_id = aws_vpc.main.id
    tags = merge (
        var.database_route_table_tags,
        local.common_tags,
        {
            Name = "${var.project}-${var.environment}-database"
        }
    )
}

# Route for Public Subnets to IGW
resource "aws_route" "public" {
    route_table_id = aws_route_table.public.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
}

# Route for Private Subnets to NAT Gateway
resource "aws_route" "private" {
    route_table_id = aws_route_table.private.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.main.id 
}

# Route for database Subnets to NAT Gateway
resource "aws_route" "database" {
    route_table_id = aws_route_table.database.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.main.id 
}

# Associate Public Subnets with the Public Route Table
resource "aws_route_table_association" "public" {
    count = length(var.public_subnet_cidrs)
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id 
}

# Associate Private Subnets with the Private Route Table
resource "aws_route_table_association" "private" {
    count = length(var.private_subnet_cidrs)
    subnet_id = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private.id 
}

# Associate Database Subnets with the Database Route Table
resource "aws_route_table_association" "database" {
    count = length(var.database_subnet_cidrs)
    subnet_id = aws_subnet.database[count.index].id
    route_table_id = aws_route_table.database.id 
}