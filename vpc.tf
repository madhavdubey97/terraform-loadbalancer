resource "aws_vpc" "madhav_vpc" {
	cidr_block           = "10.0.0.0/16"
	enable_dns_support   = "true"
	enable_dns_hostnames = "true"
	instance_tenancy     = "default"
	tags = {
		Name = "madhav_vpc"
	}
}

resource "aws_subnet" "private_subnet" {
	vpc_id                  = "${aws_vpc.madhav_vpc.id}"
	cidr_block              = "10.0.1.0/24"
	map_public_ip_on_launch = "false"
	availability_zone       = "ap-south-1a"
	tags = {
		Name = "private_subnet_madhav_vpc"
	}
}

resource "aws_subnet" "public_subnet" {
	vpc_id                  = "${aws_vpc.madhav_vpc.id}"
	cidr_block              = "10.0.2.0/24"
	map_public_ip_on_launch = "true"
	availability_zone       = "ap-south-1a"
	tags = {
		Name = "public_subnet_madhav_vpc"
	}
}

resource "aws_internet_gateway" "madhav_ig" {
	vpc_id = "${aws_vpc.madhav_vpc.id}"
	tags = {
		Name = "madhav_ig"
	}
}

resource "aws_route_table" "madhav_route_table" {
	vpc_id = "${aws_vpc.madhav_vpc.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.madhav_ig.id}"
	}
	tags = {
		Name = "madhav_route_table"
	}
}

resource "aws_route_table_association" "subnet_rtable_association" {
	subnet_id      = "${aws_subnet.public_subnet.id}"
	route_table_id = "${aws_route_table.madhav_route_table.id}"
}
