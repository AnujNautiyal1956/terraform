/*resource "aws_instance" "MyDemoInstance" {
  ami           = "ami-0080e4c5bc078760e"
  instance_type = "t2.micro"
  security_group="${aws_security_group.DemoSecurtyGroup.name}"
  tags {
    Name = "MyPrimaryInstance"
  }
}
*/
