output "control_node_ip" {
  value = "${aws_instance.my_instance_control_node.public_ip}"
}

output "manage_node_ip" {
  value = "${aws_instance.my_instance_manage_node.public_ip}"
}