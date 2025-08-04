output "instance_ids" {
  description = "Contabo instance IDs"
  value       = contabo_instance.k8s_vps[*].id
}

output "instance_names" {
  description = "Instance display names"
  value       = contabo_instance.k8s_vps[*].display_name
}
