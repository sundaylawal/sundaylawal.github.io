provider "aws" {
  region     = "us-east-1"
}

#create a vpc
resource "aws_vpc" "adoptedpet_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  
  tags = {
    Name = "adoptedpet"
  }
}


#create subnets
  resource "aws_subnet" "adoptedpet_pubsubnet1" {
  vpc_id     = aws_vpc.adoptedpet_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "adoptedpet_pubsubnet1"
  }

  }
  resource "aws_subnet" "adoptedpet_pubsubnet2" {
  vpc_id     = aws_vpc.adoptedpet_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "adoptedpet_pubsubnet2"
  }
}

  resource "aws_subnet" "adoptedpet_prisubnet1" {
  vpc_id     = aws_vpc.adoptedpet_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "adoptedpet_prisubnet1"
  }

}
  resource "aws_subnet" "adoptedpet_prisubnet2" {
  vpc_id     = aws_vpc.adoptedpet_vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private_subnet_2"
  }
}

#create internet gateway
resource "aws_internet_gateway" "adoptedpet_intgw" {
  vpc_id = aws_vpc.adoptedpet_vpc.id

  tags = {
    Name = "adoptedpet_intgw"
  }
}
resource "aws_eip" "nat" {

   depends_on = [aws_internet_gateway.adoptedpet_intgw]
}

#create nat gateway
resource "aws_nat_gateway" "adoptedpet_natgw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.adoptedpet_pubsubnet1.id

  tags = {
    Name = "adoptedpet_natgw"
  }
}

#create route tables
resource "aws_route_table" "adoptedpet_pub_rt" {
vpc_id = aws_vpc.adoptedpet_vpc.id

route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.adoptedpet_intgw.id

}

tags = {
Name = "adoptedpet_pub_rt"
}
}


resource "aws_route_table" "adoptedpet_pri_rt" {
vpc_id = aws_vpc.adoptedpet_vpc.id
route {
cidr_block = "0.0.0.0/0"
nat_gateway_id = aws_nat_gateway.adoptedpet_natgw.id
    }

tags = {
Name = "adoptedpet_pri_rt"

  }
}

#create route table association
resource "aws_route_table_association" "adoptedpet_pub_rt_as1" {
subnet_id      = aws_subnet.adoptedpet_pubsubnet1.id
route_table_id = aws_route_table.adoptedpet_pub_rt.id

}

resource "aws_route_table_association" "adoptedpet_pub_rt_as2" {
subnet_id      = aws_subnet.adoptedpet_pubsubnet2.id
route_table_id = aws_route_table.adoptedpet_pub_rt.id

}

resource "aws_route_table_association" "adoptedpet_pri_rt_as1" {
subnet_id      = aws_subnet.adoptedpet_prisubnet1.id
route_table_id = aws_route_table.adoptedpet_pri_rt.id

}

resource "aws_route_table_association" "adoptedpet_pri_rt_as2" {
subnet_id      = aws_subnet.adoptedpet_prisubnet2.id
route_table_id = aws_route_table.adoptedpet_pri_rt.id

}

#create security groups

resource "aws_security_group" "frontend" {
  name        = "frontend"
  description = "enable jenkins/tomacat/ssh access from port 8080/8085/22"
  vpc_id      = aws_vpc.adoptedpet_vpc.id

  ingress {

      description      = "tomcat access"
      from_port        = 8080
      to_port          = 8090
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }

  ingress {
      description      = "ssh access"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    }

  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
    }

  tags = {
    Name = "frontend"
  }
}

# Create backend security group
resource "aws_security_group" "backend" {
  name        = "backend"
  description = "enable mysql/aurora/ssh access fromm port 3306/22"
  vpc_id      = aws_vpc.adoptedpet_vpc.id

  ingress {
    description     = "mysql access"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.frontend.id}"]
  }

  ingress {
    description     = "ssh access"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.frontend.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "backend"
  }
}


#keypair configuration
resource "aws_key_pair" "Set6" {
  key_name   = "Set6"
  public_key = file(var.path_to_public_key)
}

# create of Jenkins server
resource "aws_instance" "jenkins_server" {
   ami                         = "ami-0b0af3577fe5e3532"
   instance_type               = "t2.medium"
   subnet_id                   = aws_subnet.adoptedpet_pubsubnet1.id
   security_groups             = ["${aws_security_group.frontend.id}"]
   associate_public_ip_address = true 
   key_name                    = "Set6"
   
   user_data       = <<-EOF
       #!/bin/bash
       sudo su 
       yum install wget -y
       yum install git -y
       wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
       rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
       yum upgrade -y
       yum install jenkins java-1.8.0-openjdk-devel -y --nobest
       systemctl start jenkins
     EOF


  root_block_device {
    volume_size   = "10"
    volume_type   = "gp2"
  }
  tags = {
     Name = "jenkins_server2"
   }
}

#create app server
resource "aws_instance" "app_server" {
  ami                         = "ami-0b0af3577fe5e3532" 
  instance_type               = "t2.medium"
  key_name                    = aws_key_pair.set-6-keypair.key_name
  subnet_id                   = aws_subnet.adoptedpet_pubsubnet1.id
  vpc_security_group_ids      = ["${aws_security_group.frontend.id}"]
  associate_public_ip_address = true
user_data = <<-EOF
#!/bin/bash
sudo su
# sudo yum update -y
# sudo yum upgrade -y
yum install java-11-openjdk-devel -y
yum install wget -y
cd /opt
wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.0.12/bin/apache-tomcat-10.0.12.tar.gz
tar -xvf apache-tomcat-10.0.12.tar.gz
rm -rf apache-tomcat-10.0.12.tar.gz
cd apache-tomcat-10.0.12/bin
chmod +x startup.sh
chmod +x shutdown.sh
ln -s /opt/apache-tomcat-10.0.12/bin/startup.sh /usr/sbin/tomcatup
ln -s /opt/apache-tomcat-10.0.12/bin/shutdown.sh /usr/sbin/tomcatdown
cat <<EOT > /opt/apache-tomcat-10.0.12/webapps/host-manager/META-INF/context.xml
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true" >
  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"
                   sameSiteCookies="strict" />
<!--  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" /> -->
  <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/>
</Context>
EOT
cat <<EOT > /opt/apache-tomcat-10.0.12/webapps/manager/META-INF/context.xml
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true" >
  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"
                   sameSiteCookies="strict" />
<!--  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" /> -->
  <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/>
</Context>
EOT
cat <<EOT > /opt/apache-tomcat-10.0.12/conf/tomcat-users.xml
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
<role rolename="manager-gui"/>
<role rolename="manager-script"/>
<role rolename="manager-jmx"/>
<role rolename="manager-status"/>
<role rolename="admin-gui"/>
<role rolename="admin-script"/>
<user username="admin" password="cloudjerky@123" roles="manager-gui, admin-gui, admin-script, manager-script, manager-jmx, manager-status"/>
</tomcat-users>
EOT
cat << EOT > /opt/apache-tomcat-10.0.12/conf/server.xml
<?xml version="1.0" encoding="UTF-8"?>
<Server port="8005" shutdown="SHUTDOWN">
  <Listener className="org.apache.catalina.startup.VersionLoggerListener" />
  <Listener className="org.apache.catalina.core.AprLifecycleListener" SSLEngine="on" />
  <Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
  <Listener className="org.apache.catalina.mbeans.GlobalResourcesLifecycleListener" />
  <Listener className="org.apache.catalina.core.ThreadLocalLeakPreventionListener" />
  <GlobalNamingResources>
    <Resource name="UserDatabase" auth="Container"
              type="org.apache.catalina.UserDatabase"
              description="User database that can be updated and saved"
              factory="org.apache.catalina.users.MemoryUserDatabaseFactory"
              pathname="conf/tomcat-users.xml" />
  </GlobalNamingResources>
  <Service name="Catalina">
    <Connector port="8085" protocol="HTTP/1.1"
               connectionTimeout="20000"
               redirectPort="8443" />
    <Engine name="Catalina" defaultHost="localhost">
            <Realm className="org.apache.catalina.realm.LockOutRealm">
        <Realm className="org.apache.catalina.realm.UserDatabaseRealm"
               resourceName="UserDatabase"/>
      </Realm>
      <Host name="localhost"  appBase="webapps"
            unpackWARs="true" autoDeploy="true">
        <Valve className="org.apache.catalina.valves.AccessLogValve" directory="logs"
               prefix="localhost_access_log" suffix=".txt"
               pattern="%h %l %u %t &quot;%r&quot; %s %b" />
      </Host>
    </Engine>
  </Service>
</Server>
EOT
tomcatdown
tomcatup
sleep 25m
cd /opt
cd apache-tomcat-10.0.12/
cd webapps/
java -jar spring-petclinic-2.4.2.war
EOF

tags = {
    Name = "tomcat_SVR"
  }
}

resource "aws_ami_from_instance" "app_server_image" {
  name               = "tomcat_server_image"
  source_instance_id = aws_instance.app_server.id
  
  depends_on = [
  aws_instance.tomcat_server
  ]
}

# creating launch configuration for webserver ASG
resource "aws_launch_configuration" "adoptedpetLC" {
  name                        = "adoptedpetLC"
  image_id                    = aws_ami_from_instance.app_server_image.id
  key_name                    = "adoptedpet"
  instance_type               = "t2.medium"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.Frontend.id]
}

creating load balancer target group
resource "aws_lb_target_group" "adoptedpetTG" {
  name             = "adoptedpetTG"
  port             = 8080
  protocol         = "HTTP"
  vpc_id           = aws_vpc.Team-us-set6_vpc.id

  health_check {
    path                = "/*"
    port                = 8080
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 200
    matcher             = "200"  
  }
}

# attaching the targeted instance to the above target group
resource "aws_lb_target_group_attachment" "adoptedpetTG" {
  target_group_arn = aws_lb_target_group.adoptedpetTG.arn
  target_id        = aws_instance.app_server.id
  port             = 8080

}

# creating load balancer
resource "aws_lb" "adoptedpetTG" {
  name               = "adoptedpetTG"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Frontend.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

}

resource "aws_lb_listener" "adoptedpetLB" {
  load_balancer_arn = aws_lb.adoptedpetLB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.adoptedpetLB.arn
  }
}

# creating of auto-scalling group 
resource "aws_autoscaling_group" "adoptedpetASG" {
  name                      = "adoptedpetASG"
  launch_configuration      = aws_launch_configuration.adoptedpetLC.id
  vpc_zone_identifier       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  target_group_arns         = [aws_lb_target_group.adoptedpetTG.arn]
  desired_capacity          = 2
  max_size                  = 4
  min_size                  = 1
}

# aws autoscaling policy
resource "aws_autoscaling_policy" "adoptedpetASG_policy" {
  name                   = "adoptedpet-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.Set6ASG.name

}
# metric alarm to activate scaling
resource "aws_cloudwatch_metric_alarm" "adoptedpetASG-Alarm" {
  alarm_name          = "adoptedpet-Alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "40"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.Set6ASG.name
  }

  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.adoptedpetASG_policy.arn]
}

# creating route 53 zone
resource "aws_route53_zone" "adoptedpet_route53_zone" {
  name = "adoptedpet_route53"

  tags = {
    Environment = "dev_adoptedpet"
  }
}
# creating route 53 "A" records and attaching the load balancer as the source
resource "aws_route53_record" "adoptedpet_A_record" {
  zone_id = aws_route53_zone.adoptedpet_route53_zone.zone_id
  name    = "adoptedpet_route53_zone.com"
  type    = "A"
 
  alias {
    name                   = aws_lb.adoptedpet.dns_name
    zone_id                = aws_lb.adoptedpet6LB.zone_id
    evaluate_target_health = false
  }
}
