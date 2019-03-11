variable "aws_region"
{
  default = "us-east-1"
}

variable "Path-to-private-key"
{
  default = "mykey"
}

variable "AMIS" {
  type = "map"
  default = {
    us-east-1 = "ami-13be557e"
    us-west-2 = "ami-01e24be29428c15b2"
    eu-west-1 = "ami-844e0bf7"
  }
}

/*{
default = ["${C:\Users\Z0041MAA\Desktop\keypairs\}"]
}
*/
