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
resource "aws_key_pair" "set-6-keypair" {
  key_name   = "set-6-keypair"
  public_key = file(var.path_to_public_key)
}

# create of Jenkins server
resource "aws_instance" "jenkins_server" {
   ami                         = "ami-0b0af3577fe5e3532"
   instance_type               = "t2.medium"
   subnet_id                   = aws_subnet.adoptedpet_pubsubnet1.id
   security_groups             = ["${aws_security_group.frontend.id}"]
   associate_public_ip_address = true 
   key_name                    = "set-6-keypair"
   
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
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.set-6-keypair.key_name
  subnet_id                   = aws_subnet.adoptedpet_pubsubnet1.id
  vpc_security_group_ids      = ["${aws_security_group.frontend.id}"]
  associate_public_ip_address = true

user_data = <<-EOF
#!/bin/bash
sudo su
# sudo yum update -y
# sudo yum upgrade -y
yum install java-1.8.0-openjdk-devel -y
groupadd --system tomcat
useradd -d /usr/share/tomcat -r -s /bin/false -g tomcat tomcat
yum install wget -y
cd /opt
wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.54/bin/apache-tomcat-9.0.54.tar.gz
tar -xvf apache-tomcat-9.0.54.tar.gz
mv apache-tomcat-9.0.54 tomcat9
rm -rf apache-tomcat-9.0.54.tar.gz
chown -R tomcat:tomcat /opt/tomcat9
cd tomcat9/bin/
ln -s /opt/tomcat9/bin/startup.sh /usr/sbin/tomcatup
ln -s /opt/tomcat9/bin/shutdown.sh /usr/sbin/tomcatdown
cat <<EOT > /opt/tomcat9/webapps/nagerhost-ma/META-INF/context.xml
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true" >
  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"
                   sameSiteCookies="strict" />
<!--  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" /> -->
  <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/>
</Context>
EOT
cat <<EOT > /opt/tomcat9/webapps/manager/META-INF/context.xml
<?xml version="1.0" encoding="UTF-8"?>
<Context antiResourceLocking="false" privileged="true" >
  <CookieProcessor className="org.apache.tomcat.util.http.Rfc6265CookieProcessor"
                   sameSiteCookies="strict" />
<!--  <Valve className="org.apache.catalina.valves.RemoteAddrValve"
         allow="127\.\d+\.\d+\.\d+|::1|0:0:0:0:0:0:0:1" /> -->
  <Manager sessionAttributeValueClassNameFilter="java\.lang\.(?:Boolean|Integer|Long|Number|String)|org\.apache\.catalina\.filters\.CsrfPreventionFilter\$LruCache(?:\$1)?|java\.util\.(?:Linked)?HashMap"/>
</Context>
EOT
cat <<EOT > /opt/tomcat9/conf/tomcat-users.xml
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
<role rolename="manager-gui"/>
<role rolename="manager-script"/>
<role rolename="manager-jmx"/>
<role rolename="manager-status"/>
<user username="admin" password="admin@123" roles="manager-gui, manager-script, manager-jmx, manager-status"/>
<user username="deployer" password="deployer@123" roles="manager-script"/>
<user username="tomcat" password="team3@s3cret" roles="manager-gui"/>
</tomcat-users>
EOT
cat << EOT > /opt/tomcat9/conf/server.xml
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
EOF
tags = {
    Name = "app_server"
  }
}
