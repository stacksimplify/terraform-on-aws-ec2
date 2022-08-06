# Terraform Output Values


# EC2 Instance Public IP with TOSET

# EC2 Instance Public DNS with TOSET


# EC2 Instance Public DNS with TOMAP



/*
# Additional Important Note about OUTPUTS when for_each used
1. The [*] and .* operators are intended for use with lists only. 
2. Because this resource uses for_each rather than count, 
its value in other expressions is a toset or a map, not a list.
3. With that said, we can use Function "toset" and loop with "for" 
to get the output for a list
4. For maps, we can directly use for loop to get the output and if we 
want to handle type conversion we can use "tomap" function too 
*/

