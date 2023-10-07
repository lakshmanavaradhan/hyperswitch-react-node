variable "vpc_id" {
   type = string
   description = "VPC_ID"
   default = null
}

variable "keypair" {
   type = string
   description = "key"
   default = "read_vicky"
}

variable "ami_id" {
   type = string
   description = "ami_id"
   default = null
}
