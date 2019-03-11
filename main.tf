##################provider################################

provider "aws" {
  access_key = "ASIASNNUJJ3P4YHOXKHN"
  secret_key = "H5EzgiY7kmof/eNTwjpXmcV4r8/Uxc9lBFRbWYyG"
  region     = "us-west-2"
}



##########################SECURITY GROUP##########################

resource "aws_security_group" "DemoSecurtyGroup" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.MainVPC.id}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "allow-ssh"
  }
}




##########################VPC###############################



################### INTERNET VPC########################
resource "aws_vpc" "MainVPC" {
cidr_block       = "10.0.0.0/16"
instance_tenancy = "default"

tags = {
  Name = "main"
}
}

########################subnets################################
resource "aws_subnet" "main-public-1" {
    vpc_id="${aws_vpc.MainVPC.id}"
    cidr_block="10.0.1.0/24"
    availability_zone="us-west-1b"

    tags {
      Name = "main-public-1"
    }
}

resource "aws_subnet" "main-public-2" {
    vpc_id="${aws_vpc.MainVPC.id}"
    cidr_block="10.0.2.0/24"
    availability_zone="us-west-1b"

    tags {
      Name = "main-public-2"
    }
}

resource "aws_subnet" "main-public-3" {
    vpc_id="${aws_vpc.MainVPC.id}"
    cidr_block="10.0.3.0/24"
    availability_zone="us-west-1c"

    tags {
      Name = "main-public-3"
    }
}

resource "aws_subnet" "main-private-1" {
    vpc_id="${aws_vpc.MainVPC.id}"
    cidr_block="10.0.4.0/24"
    availability_zone="us-west-1b"

    tags {
      Name = "main-private-1"
    }
}

resource "aws_subnet" "main-private-2" {
    vpc_id="${aws_vpc.MainVPC.id}"
    cidr_block="10.0.5.0/24"
    availability_zone="us-west-1b"

    tags {
      Name = "main-private-2"
    }
}

resource "aws_subnet" "main-private-3" {
    vpc_id="${aws_vpc.MainVPC.id}"
    cidr_block="10.0.6.0/24"
    availability_zone="us-west-1c"
    tags {
      Name = "main-private-3"
    }
}

####################INTERNET-GATEWAY########################
resource "aws_internet_gateway" "main_gw" {
  vpc_id="${aws_vpc.MainVPC.id}"
  tags {
    Name = "Main-Gateway"

  }

}

#############################ROUTE TABLES####################
resource "aws_route_table" "main_public" {
    vpc_id="${aws_vpc.MainVPC.id}"
    route{
      cidr_block="0.0.0.0/0"
      gateway_id="${aws_internet_gateway.main_gw.id}"
    }

      tags {
        Name = "main-public-route"
      }

}

##################route association public#######################

resource "aws_route_table_association" "main-public-1-a" {
  subnet_id="${aws_subnet.main-public-1.id}"
  route_table_id="${aws_route_table.main_public.id}"
    }

    resource "aws_route_table_association" "main-public-1-b" {
        subnet_id="${aws_subnet.main-public-2.id}"
        route_table_id="${aws_route_table.main_public.id}"
    }


        resource "aws_route_table_association" "main-public-1-c" {
            subnet_id="${aws_subnet.main-public-3.id}"
            route_table_id="${aws_route_table.main_public.id}"
        }


#############autoscalingandLC####################

resource "aws_launch_configuration" "examplelaunchconfiguration" {
name          = "web_config"
 image_id      = "${lookup(var.AMIS,var.aws_region)}"
 instance_type = "t2.micro"
 security_groups =["${aws_security_group.DemoSecurtyGroup.id}"]
 }

 resource "aws_autoscaling_group" "exampleautoscalinggroup" {
   name = "MyDemoAutoscalingGroup"
   vpc_zone_identifier=["${aws_subnet.main-public-1.id}","${aws_subnet.main-public-2.id}"]
   launch_configuration="${aws_launch_configuration.examplelaunchconfiguration.name}"
   min_size= 1
   max_size= 3
   health_check_grace_period=300
   health_check_type="EC2"
   force_delete=true

   tag {
      key = "Name"
      value = "ec2 instance"
      propagate_at_launch = true
  }
}


###################AUTOSCALINGPOLICY########################



##########scale up alarm#########
resource "aws_autoscaling_policy" "examplepolicy" {
  name                   = "example cpu-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = "${aws_autoscaling_group.exampleautoscalinggroup.name}"
  policy_type="SimpleScaling"

}

resource "aws_cloudwatch_metric_alarm" "cpu-alarm" {
  alarm_name          = "example-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"


  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.exampleautoscalinggroup.name}"
    }

    alarm_description = "This metric monitors ec2 cpu utilization"
  actions_enabled=true
  alarm_actions     = ["${aws_autoscaling_policy.examplepolicy.arn}"]
}


#############scale down alarm##################

resource "aws_autoscaling_policy" "cpu-scaledown-policy" {
    name = "example-cpu-dpwn-policy"
    autoscaling_group_name="${aws_autoscaling_group.exampleautoscalinggroup.name}"
    scaling_adjustment=1
    adjustment_type="ChangeInCapacity"
    cooldown=300
    policy_type="SimpleScaling"
    }
    resource "aws_cloudwatch_metric_alarm" "cpu-scale-downalarm" {
      alarm_name="example-cpuscale-down-policy"
      comparison_operator="GreaterThanOrEqualToThreshold"
      evaluation_periods="2"
      metric_name="CPUUtilization"
      namespace="AWS/EC2"
      period="120"
      statistic="Average"
      threshold="30"

      dimensions ={
        AutoScalingGroupName="${aws_autoscaling_group.exampleautoscalinggroup.name}"
      }
      alarm_description="This metric monitors the alarm down policy"
      actions_enabled=true
      alarm_actions=["${aws_autoscaling_policy.examplepolicy.arn}"]

    }
