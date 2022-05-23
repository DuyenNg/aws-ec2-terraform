variable "region" {
  default = "ap-south-1"
  description = "AWS Region"
}

variable "ami" {
  default = "ami-05ba3a39a75be1ec4"
  type = string
  description = "Amazon Machine Image ID for Ubuntu Server 20.04"
}

variable "instance_count" {
  default = "1"
  description = "Number of Instances"
}

variable "associate_public_ip_address" {
  default = true
  type = bool
  description = "Associate a public IP address with an instance in a VPC"
}

variable "placement_group" {
  default     = false
  type        = bool
  description = "The Placement Group"
}

variable "capacity_reservation_preference" {
  default     = "open"
  type        = string
  description = "Describes an instance's Capacity Reservation preferences"
}

variable "disable_api_termination" {
  default     = false
  type        = bool
  description = "EC2 Instance Termination Protection"
}

variable "monitoring" {
  default     = false
  type        = bool
  description = "CloudWatch detailed monitoring"
}

variable "tenancy" {
  default     = "Shared"
  type        = string
  description = "The tenancy of the instance"
}

variable "enclave_options_enabled" {
  default     = false
  type        = bool
  description = "Nitro Enclaves"
}

variable "hibernation" {
  default     = false
  type        = bool
  description = "Hibernation behavior"
}

variable "instance_initiated_shutdown_behavior" {
  default     = null
  type        = string
  description = "Shutdown behavior"
}

variable "instance_type" {
  default = "t2.micro"
  type = string
  description = "Size of VM"
}

variable "cpu_credits" {
  default     = "unlimited"
  type        = string
  description = "The credit option for CPU usage"
}

variable "root_block_device" {
  type = list( object({
      size = number
      encrypted = bool
  }))

  default = [ {
    size = 10
    encrypted = false
  } ]

  description = "An instance's storage device"
}

variable "ingress_rules" {
  type = list( object({
      from_port = number
      to_port = number
      protocol = string
      cidr_blocks = list(string)
  }))

  default = [ {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "10.0.0.0/16" ]
  },
  {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "113.160.247.64/32", "123.19.59.37/32" ]
  } ]

  description = "Inbound rules"
}

variable "egress_rules" {
  type = list( object({
      from_port = number
      to_port = number
      protocol = string
      cidr_blocks = list(string)
  }))

  default = [ {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  } ]

  description = "Outbound rules"
}

variable "enable_dns_support" {
  default = true
  type = bool
  description = "DNS support in the VPC"
}

variable "enable_dns_hostnames" {
  default = true
  type = bool
  description = "DNS hostnames in the VPC"
}

variable "enable_classiclink" {
  default = false
  type = bool
  description = "ClassicLink DNS Support for the VPC"
}

variable "instance_tenancy" {
  default = "default"
  type = string
  description = "A tenancy option for instances launched into the VPC"
}

variable "map_public_ip_on_launch" {
  default = true
  type = bool
  description = "Specify true to indicate that instances launched into the subnet should be assigned a public IP address"
}

variable "availability_zones" {
  default = ["ap-south-1a","ap-south-1b"]
  type = list(string)
  description = "List of Availability Zones"
}

variable "alb_ingress_rules" {
  type = list( object({
      from_port = number
      to_port = number
      protocol = string
      cidr_blocks = list(string)
  }))

  default = [ {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  },
  {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  } ]

  description = "Application load balancer inbound rules"
}

variable "alb_egress_rules" {
  type = list( object({
      from_port = number
      to_port = number
      protocol = string
      cidr_blocks = list(string)
  }))

  default = [ {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  } ]

  description = "Application load balancer outbound rules"
}

# ACM
variable "certificate_arn" {
  description = "ARN of certificate issued by AWS ACM. If empty, a new ACM certificate will be created and validated using Route53 DNS"
  type        = string
  default     = "arn:aws:acm:ap-south-1:596912130800:certificate/b0a6386b-2f3a-4e0d-8da5-f197d6beceeb"
}

# Route53 hosted zone
variable "route53_hosted_zone_name" {
  description = "Route53 hosted zone name"
  type = string
  default = "developer07.tasdg.info"
}