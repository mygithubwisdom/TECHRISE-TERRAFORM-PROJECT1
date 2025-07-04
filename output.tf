output "public_web_server_dns" {
  description = "Public IPv4 DNS of the web server"
  value       = aws_instance.Publicweb_server.public_dns
}


output "private_db_server_dns" {
  description = "Private IPv4 DNS of the database server"
  value       = aws_instance.PrivateDB_server.private_dns
}


output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.KCVPC.id
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.PublicSubnet.id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = aws_subnet.PrivateSubnet.id
}

output "public_security_group_id" {
  description = "The ID of the public security group"
  value       = aws_security_group.public_sg.id
}

output "private_security_group_id" {
  description = "The ID of the private security group"
  value       = aws_security_group.private_sg.id
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway"
  value       = aws_internet_gateway.IGW.id
}

output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.PublicRouteTable.id
}

output "private_route_table_id" {
  description = "The ID of the private route table"
  value       = aws_route_table.PrivateRouteTable.id
}