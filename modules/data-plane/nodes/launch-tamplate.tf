resource "aws_launch_template" "launch_template" {
 name_prefix = "${var.cluster_name}-launch-template-"
####################################

# Note: For EKS node groups, AWS automatically handles the bootstrap script
# If you need custom user_data, ensure it doesn't conflict with EKS bootstrap
# image_id = "ami-0eddf4b3eca8324cc"  # Commented out - let EKS choose the AMI
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
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }
  network_interfaces {
   associate_public_ip_address = false
  } 
  
  # Note: For EKS managed node groups, AWS handles bootstrap automatically
  # No user_data needed - EKS manages node bootstrap
  
  tag_specifications {
    resource_type = "instance"
     tags = {
        name = "instance-with-custom-launch-template"
      }
  }
}