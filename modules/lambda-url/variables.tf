variable "function_name" {
  description = "Name for the Lambda function"
  type        = string
}

variable "source_dir" {
  description = "Path to the directory containing the Lambda's handler code"
  type        = string
}

variable "handler" {
  description = "Function entrypoint, e.g. handler.handler"
  type        = string
  default     = "handler.handler"
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.12"
}