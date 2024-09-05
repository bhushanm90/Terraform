#Create VPC
resource "aws_vpc" "bm-vpc" {
  cidr_block = var.cidr
  tags = {
     Name = "dev"
   }

}

#Create public subnet1  in AZ1
resource "aws_subnet" "bm-public-subnet1" {
  vpc_id = aws_vpc.bm-vpc.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  
}

#Create public subnet1  in AZ2
resource "aws_subnet" "bm-public-subnet2" {
  vpc_id = aws_vpc.bm-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

#Create Internet Gateway

resource "aws_internet_gateway" "bm-igw-tf" {
  vpc_id = aws_vpc.bm-vpc.id 
  tags = {
    Name = "dev-igw"
  }
}

resource "aws_route_table" "bm-aws-route" {
  vpc_id = aws_vpc.bm-vpc.id 

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.bm-igw-tf.id
  }

}

resource "aws_route_table_association" "bm-router-associate1" {
   subnet_id = aws_subnet.bm-public-subnet1.id
   route_table_id = aws_route_table.bm-aws-route.id 
}

resource "aws_route_table_association" "bm_router_associate2" {
   subnet_id = aws_subnet.bm-public-subnet2.id
   route_table_id = aws_route_table.bm-aws-route.id
}

resource "aws_security_group" "bm-terr-sg" {
  name        = "web-sg"
  vpc_id      = aws_vpc.bm-vpc.id

  ingress {
    description = "Http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bm-sg"
  }
}

resource "aws_s3_bucket" "bm-s3" {
   bucket = "bm-terraform-project-demo"
   tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_instance" "bm-ec2-instance1" {
    ami    = "ami-0e86e20dae9224db8"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.bm-terr-sg.id]
    subnet_id = aws_subnet.bm-public-subnet1.id
    user_data = base64encode(file("userdata.sh"))
    tags = {
      Name = "terraform-demo1"
  }
}
resource "aws_instance" "bm-ec2-instance2" {
    ami    = "ami-0e86e20dae9224db8"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.bm-terr-sg.id]
    subnet_id = aws_subnet.bm-public-subnet2.id
    user_data = base64encode(file("userdata1.sh"))
    tags = {
      Name = "terraform-demo2"
  }
}

#Create load balancer
resource "aws_lb" "my-alb" {
  name = "mylb"
  internal = false 
  load_balancer_type = "application"
  security_groups = [aws_security_group.bm-terr-sg.id]
  subnets = [aws_subnet.bm-public-subnet1.id,aws_subnet.bm-public-subnet2.id]
  tags = {
     Name ="web-alb"
   }
    
}

resource "aws_lb_target_group" "bm-target-group" {
  name = "mytarget"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.bm-vpc.id
  health_check {
    path = "/"
    port = "traffic-port"
  }
  
}


#Attache target group
resource "aws_lb_target_group_attachment" "attach-tg" {
  target_group_arn = aws_lb_target_group.bm-target-group.arn
  target_id = aws_instance.bm-ec2-instance1.id
  }

resource "aws_lb_listener" "lb-listener" {
  load_balancer_arn = aws_lb.my-alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.bm-target-group.arn
    type = "forward"

  }
}

output "loadbalancerdns" {
   value = aws_lb.my-alb.dns_name
}