resource "aws_vpc" "bm_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "dev"
  }

}

resource "aws_subnet" "bm_public_subnet" {
  vpc_id                  = aws_vpc.bm_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "dev-Public"
  }

}

resource "aws_internet_gateway" "bm_internet_gateway" {
  vpc_id = aws_vpc.bm_vpc.id
  tags = {
    Name = "dev-igw"
  }
} 

resource "aws_route_table" "bm_route_table"{
  vpc_id = aws_vpc.bm_vpc.id 
  tags = {
    Name = "dev_public_rt"
  }
}