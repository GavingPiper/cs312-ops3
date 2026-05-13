output "minecraft_public_ip" {
  description = "Public IP of the minecraft instance: SSH here from your laptop"
  value       = aws_instance.minecraft.public_ip
}

output "minecraft_private_ip" {
  description = "Private IP of the minecraft instance: use this in the Ansible inventory"
  value       = aws_instance.minecraft.private_ip
}

output "ecr_repository_url" {
  description = "ECR repository URL: use this in the GitHub Actions workflow"
  value       = aws_ecr_repository.minecraft.repository_url
}

output "s3_bucket_url" {
  description = "An s3 bucket used to styore the world data of the minecraft server"
  value	      = aws_s3_bucket.world.id
}

output "vpc_id" {
  description = "ID of the provisioned VPC"
  value       = aws_vpc.cs312.id
}


