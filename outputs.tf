output "vpc_id" {
    value = aws_vpc.main.id
}

output "public_subnet_ids" {
   value = aws_subnet.public[*].id
}
#because we are using multiple public subnets, we are outputting a list of IDs
#and this should be stored in ssm parameter as a comma-separated string

output "private_subnet_ids" {
   value = aws_subnet.private[*].id
}

output "database_subnet_ids" {
   value = aws_subnet.database[*].id
}