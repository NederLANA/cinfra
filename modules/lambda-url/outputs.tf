output "function_url" {
  description = "Public URL to invoke this Lambda"
  value       = aws_lambda_function_url.this.function_url
}

output "function_name" {
  value = aws_lambda_function.this.function_name
}