terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  backend "s3" {
    bucket         = "cinfra-terraform-state-495398516515"
    key            = "cinfra/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "cinfra-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-west-1"
}

module "character_counter" {
  source = "./modules/lambda-url"

  function_name = "character-counter"
  source_dir    = "${path.root}/lambdas/character-counter"
}

module "json_validator" {
  source = "./modules/lambda-url"

  function_name = "json-validator"
  source_dir    = "${path.root}/lambdas/json-validator"
}

output "character_counter_url" {
  value = module.character_counter.function_url
}

output "json_validator_url" {
  value = module.json_validator.function_url
}