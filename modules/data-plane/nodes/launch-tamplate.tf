resource "aws_launch_template" "launch_template" {
 name = "custom-launch-template"
####################################
#optimized ami for k8s version 1.31 is ami-0eddf4b3eca8324cc
/* start with K8s version 1.30 image ID ami-0dcb2d7d97bcda689 and change it 
to k8s version 1.31 after cluster upgrade
*/
image_id = "ami-0eddf4b3eca8324cc"
 block_device_mappings {
    device_name = "/dev/sdf"
    ebs {
      volume_size = 50
    }
  }
  ebs_optimized = true
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  network_interfaces {
   associate_public_ip_address = false
  } 
#user data encoding
user_data = filebase64("${path.module}/user-data.sh")
  tag_specifications {
    resource_type = "instance"
     tags = {
        name = "instance-with-custom-launch-template"
      }
  }
}