output "VPC-ID" {
  value = aws_subnet.dwn-subnet-2a-1.vpc_id
  
}

output "ASG-desired-capacity" {
    value = aws_autoscaling_group.dwn-ASG.desired_capacity
  
}

output "ASG-max-capacity" {
    value = aws_autoscaling_group.dwn-ASG.max_size
  
}

output "ASG-min-capacity" {
    value = aws_autoscaling_group.dwn-ASG.min_size
  
}






 