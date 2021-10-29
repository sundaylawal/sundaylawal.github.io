provider "aws" {
  region     = "us-east-1"
}

# creating vpc
resource "aws_vpc" "Team-us-set6_vpc" {
  cidr_block        = "10.0.0.0/16"
  #instance_tenancy = "default"

  tags = {
    Name = "Team-us-set6_vpc"
  }
}
# creating first public subnet
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.Team-us-set6_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Public_subnet_1"
  }
}
#   creating second public subnet
resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.Team-us-set6_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Public_subnet_2"
  }
}
# creating a single private subnet
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.Team-us-set6_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private_subnet_1"
  }
}
# creating front end security group
resource "aws_security_group" "Frontend" {
  name        = "Frontend"
  description = "enable http/ssh access fromm port 8080/22"
  vpc_id      = aws_vpc.Team-us-set6_vpc.id

  ingress {
    description = "http access"
    from_port   = 8080
    to_port     = 8085
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "Frontend"
  }
}
# creating backend security group
resource "aws_security_group" "Backend" {
  name        = "Backend"
  description = "enable mysql/aurora/ssh access fromm port 3306/22"
  vpc_id      = aws_vpc.Team-us-set6_vpc.id

  ingress {
    description     = "mysql access"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.Frontend.id}"]
  }

  ingress {
    description     = "ssh access"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.Frontend.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "Backend"
  }
}
resource "aws_internet_gateway" "set6_INTGW" {
  vpc_id = aws_vpc.Team-us-set6_vpc.id

  tags = {
    Name = "set6_INTGW"
  }
}
resource "aws_eip" "nat" {
  depends_on = [aws_internet_gateway.set6_INTGW]
}
resource "aws_nat_gateway" "set6_NTGW" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "set6_NTGW"
  }
}

resource "aws_route_table" "Set6_Pub_RT" {
  vpc_id = aws_vpc.Team-us-set6_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.set6_INTGW.id
  }

  tags = {
    Name = "Set6_Pub_RT"
  }
}


resource "aws_route_table" "Set6_Pri_RT" {
  vpc_id = aws_vpc.Team-us-set6_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.set6_NTGW.id
  }

  tags = {
    Name = "Set6_Pri_RT"
  }
}


resource "aws_route_table_association" "Set6_Pub_RT_AS1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.Set6_Pub_RT.id
}


resource "aws_route_table_association" "Set6_Pub_RT_AS2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.Set6_Pub_RT.id
}


resource "aws_route_table_association" "Set6_Pri_RT_AS1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.Set6_Pri_RT.id
}

# creating jenkins server keypair
resource "aws_key_pair" "Set6" {
  key_name   = "Set6"
  public_key = file(var.path_to_public_key)
}

# creating jenkins server
resource "aws_instance" "jenkins_server" {
   ami             = "ami-0b0af3577fe5e3532"
   instance_type   = "t2.medium"
   subnet_id       = aws_subnet.public_subnet_2.id
   security_groups = ["${aws_security_group.Frontend.id}"]
   associate_public_ip_address = true 
   key_name        = "Set6"
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
  lifecycle {
    prevent_destroy = false
  }
  tags = {
     Name = "jenkins_server"
   }
}

# creating tomcat_server keypair
resource "aws_key_pair" "tomcat_key_pair" {
  key_name   = "Set6"
  public_key = file(var.path_to_public_key)
}

# creating tomcat server
resource "aws_instance" "tomcat_server" {
  ami                         = "ami-0b0af3577fe5e3532" 
  instance_type               = "t2.medium"
  key_name                    = "Set6"
  subnet_id                   = aws_subnet.public_subnet_1.id
  vpc_security_group_ids      = ["${aws_security_group.Frontend.id}"]
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
<user username="admin" password="admin@123" roles="manager-gui, admin-gui, admin-script, manager-script, manager-jmx, manager-status"/>
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
resource "aws_launch_configuration" "Set6LC" {
  name                        = "Set6LC"
  image_id                    = aws_ami_from_instance.app_server_image.id
  key_name                    = "babe"
  instance_type               = "t2.medium"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.Frontend.id]
}

creating load balancer target group
resource "aws_lb_target_group" "Set6TG" {
  name             = "SET6TG"
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
resource "aws_lb_target_group_attachment" "Set6TG" {
  target_group_arn = aws_lb_target_group.Set6TG.arn
  target_id        = aws_instance.app_server.id
  port             = 8080

}

# creating load balancer
resource "aws_lb" "Set6LB" {
  name               = "Set6LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Frontend.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

}

resource "aws_lb_listener" "Set6LB" {
  load_balancer_arn = aws_lb.Set6LB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.Set6TG.arn
  }
}

# creating of auto-scalling group 
resource "aws_autoscaling_group" "Set6ASG" {
  name                      = "Set6ASG"
  launch_configuration      = aws_launch_configuration.Set6LC.id
  vpc_zone_identifier       = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  target_group_arns         = [aws_lb_target_group.Set6TG.arn]
  desired_capacity          = 2
  max_size                  = 4
  min_size                  = 1
}

# aws autoscaling policy
resource "aws_autoscaling_policy" "Set6ASG_policy" {
  name                   = "Set6ASG-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.Set6ASG.name

}
# metric alarm to activate scaling
resource "aws_cloudwatch_metric_alarm" "Set6ASG-Alarm" {
  alarm_name          = "Set6ASG-Alarm"
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
  alarm_actions     = [aws_autoscaling_policy.Set6ASG_policy.arn]
}

# creating route 53 zone
resource "aws_route53_zone" "set6_route53_zone" {
  name = "set6usteam.us"

  tags = {
    Environment = "dev_set6"
  }
}
# creating route 53 "A" records and attaching the load balancer as the source
resource "aws_route53_record" "set6_A_record" {
  zone_id = aws_route53_zone.set6_route53_zone.zone_id
  name    = "usteamset6.com"
  type    = "A"
 
  alias {
    name                   = aws_lb.Set6LB.dns_name
    zone_id                = aws_lb.Set6LB.zone_id
    evaluate_target_health = false
  }
}
