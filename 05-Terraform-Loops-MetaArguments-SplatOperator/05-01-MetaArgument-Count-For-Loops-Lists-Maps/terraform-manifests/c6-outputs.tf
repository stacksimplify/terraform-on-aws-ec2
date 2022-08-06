#outputs
output "for_output_list" {
  description = "for loop with list"
  value = [for instance in aws_instance.myec2vm: instance.public_dns]
}








#output for loop with map
output "for_output_map" {
  description = "for loop with map"
  value = {for instance in aws_instance.myec2vm: instance.id => instance.public_dns}
}


# output for loop with map advanced
output "for_output_map_advanced" {
  description = "for loop with map advanced"
  value = {for c, instance in aws_instance.myec2vm: c => instance.public_dns}
}

#output with generalized splat operator 
output "for_generalized_splat" {
  description = "for loop with map advanced"
  value =aws_instance.myec2vm[*].public_dns
}
