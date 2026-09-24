
# Cinfra — Self-Service Lambda Deployment

A reusable, self-service way for development teams to deploy AWS Lambdas
accessible via a public URL — no AWS knowledge required.

This repo currently deploys two Lambdas as an example:

| Lambda | What it does | URL output |
| `character-counter` | Takes a string, returns its character count | `character_counter_url` |
| `json-validator` | Takes a JSON string, returns whether it's valid | `json_validator_url` |

---

## How it works

1. Write a Lambda handler in a folder under `lambdas/`.
2. Add ~4 lines to the root `main.tf` calling the shared `lambda-url` module.
3. Push to `main`.
4. GitHub Actions deploys it and returns a live https url.

#Module handles IAM, Terraform state, and AWS resources.

---

## Add Lambda

**1. Write handler**

Create a new folder under `lambdas/`, e.g. `lambdas/my-function/handler.py`:

```python
def handler(event, context):
    body = event.get("body") or ""
    if event.get("isBase64Encoded"):
        import base64
        body = base64.b64decode(body).decode("utf-8")

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"result": "..."})
    }
```

Notes:
- Function must be named `handler` in a file named `handler.py` (otherwise pass a custom `handler` value — see below).
- `event["body"]` is where the raw request body arrives (a string). It may arrive base64-encoded — the snippet above handles both cases.
- Return value must include `statusCode` and `body` — this is what turns function into a working http response.

**2. Register it in the root `main.tf`**

```hcl
module "my_function" {
  source = "./modules/lambda-url"

  function_name = "my-function"
  source_dir    = "${path.root}/lambdas/my-function"
}

output "my_function_url" {
  value = module.my_function.function_url
}
```

That's the whole interface. `handler` (default: `handler.handler`) and `runtime` (default: `python3.12`) can be overridden if you need something different:

```hcl
module "my_function" {
  source        = "./modules/lambda-url"
  function_name = "my-function"
  source_dir    = "${path.root}/lambdas/my-function"
  handler       = "app.main"
  runtime       = "python3.13"
}
```

**3. Push to `main`**

```bash
git add lambdas/my-function main.tf
git commit -m "Add my-function Lambda"
git push origin main
```

GitHub Actions. Check the **Actions** tab in GitHub for progress; once it finishes, find Lambda's url in the Terraform output, visible in the workflow log or by running `terraform output` locally. Github debug spotter is helpful.

**4. Call it**

```bash
curl -X POST "<your-function-url>" -d "your input here"
```

---

## What the module does automatically

Every Lambda deployed through `modules/lambda-url` gets, with zero extra config:

- A dedicated, least-privilege IAM execution role (basic CloudWatch Logs access only)
- A public Lambda Function url (HTTPS, no API Gateway/ALB needed)
- The resource-based permissions required for that url to actually be publicly callable 
- CloudWatch log group (created automatically by Lambda on first invoke)

## Architecture decisions

- **Lambda Function urls, not API Gateway** — the brief needs "a url," not throttling/custom domains/auth. Function urls meet exactly this, and they keep the module far simpler for other developers to trust and use easily.
- **Public (`NONE`) auth** — internal dev teams just need to hit a url. In a stricter production setting you'd likely add `AWS_IAM` auth or put this behind API Gateway with an API key.
- **Remote Terraform state (S3 + DynamoDB)** — required for a team-usable setup; local state doesn't work once more than one person (or one CI pipeline) needs to apply changes.
- **GitHub Actions + OIDC, no stored AWS credentials** — the deploy pipeline assumes an IAM role via short-lived OIDC tokens. No developer needs AWS credentials on their machine, and nothing sensitive is stored in GitHub secrets.

## Repository layout

```
.
├── .github/workflows/deploy.yml   # CI: push to main -> terraform apply
├── bootstrap/                     # One-time setup (state backend, OIDC role) — not touched day-to-day
├── modules/lambda-url/            # The reusable module
├── lambdas/
│   ├── character-counter/handler.py
│   └── json-validator/handler.py
└── main.tf                        # Calls the module once per Lambda
```

## Local development / testing a change before pushing

```bash
terraform init
terraform plan
```

Review the plan output before merging to `main` . CI applies automatically on every push to `main`, so `plan` locally is your safety check (or via PR).


