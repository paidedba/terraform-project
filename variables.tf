variable "vpc_prefix" {
  description = "cidr block for vpc"
  type        = string
  default = "10.0.0.0/16"
  
}

variable "subnet_prefix" {
  description = "cidr block for subnet"
  #type        = string
  
}

