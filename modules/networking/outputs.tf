output "vpc_id" {
  value = aws_vpc.this.id
}
output "subnet_ids" {
  value = aws_subnet.public[*].id
}
output "azs" {
  value = data.aws_availability_zones.available.names
}