# Node Security

# If we want to allow access to certain services on the cluster nodes like ssh access or allow secure access to an application from a client
# We do so by attaching additional rules to the security group of the worker nodes. 

# We are creating the security group rules that open the port 443 on the nodes to allow outbound calls to the Internet 
resource "aws_security_group_rule" "https_port" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = var.cluster_security_group_id
}

