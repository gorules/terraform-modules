# AI LLM Configuration

Optional AI assistant integration for BRMS. Configures LLM providers, model parameters, and API key management.

## Supported Providers

| Provider | Value | API Key Required | IAM Required |
|----------|-------|-----------------|-------------|
| OpenAI | `openai` | Yes | No |
| Anthropic | `anthropic` | Yes | No |
| Google | `google` | Yes | No |
| Amazon Bedrock | `amazon-bedrock` | No | Yes |
| Azure OpenAI | `azure-openai` | Yes | No |

## Configuration

```hcl
brms = {
  ai = {
    provider            = "anthropic"
    model               = "claude-sonnet-4-20250514"
    api_key_secret_arn  = "arn:aws:secretsmanager:us-east-1:123456789012:secret:anthropic-key-abc123"
    temperature         = 0.4      # 0.0 - 2.0 (default 0.4)
    context_window      = null     # Provider default
    max_output_tokens   = 32000    # Default 32000
    thinking_level      = "medium" # high, medium
  }
}
```

## Environment Variables Generated

When AI is enabled, these env vars are set on the BRMS container:

| Variable | Value | Conditional |
|----------|-------|-------------|
| LLM_PROVIDER | Provider name | Always |
| LLM_MODEL | Model identifier | Always |
| LLM_TEMPERATURE | Temperature value | Always |
| LLM_MAX_OUTPUT_TOKENS | Token limit | Always |
| LLM_THINKING_LEVEL | Thinking depth | Always |
| LLM_CONTEXT_WINDOW | Window size | Only if explicitly set |
| LLM_AZURE_RESOURCE_NAME | Azure resource | Only for azure-openai |

## Secrets

| Secret | Env Var | Condition |
|--------|---------|----------|
| AI API key | LLM_API_KEY | All providers except amazon-bedrock |

The API key is stored in Secrets Manager (user-provided ARN) and injected via the ECS task execution role. See [Secrets Management](secrets-management.md).

## Amazon Bedrock (IAM-Based)

Bedrock is unique — no API key needed. Instead, the BRMS task role gets an IAM policy:

```hcl
data "aws_iam_policy_document" "brms_bedrock_access" {
  statement {
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
    ]
    resources = ["arn:aws:bedrock:*::foundation-model/*"]
  }
}

resource "aws_iam_policy" "brms_bedrock_access" {
  name   = "${var.name_prefix}-brms-bedrock-access"
  policy = data.aws_iam_policy_document.brms_bedrock_access.json
}
```

This grants access to all foundation models in all regions. The policy is attached to the BRMS task role. See [IAM Architecture](iam-architecture.md) for how all policies compose together.

## Azure OpenAI

Requires additional `azure_resource_name` parameter:

```hcl
brms = {
  ai = {
    provider            = "azure-openai"
    model               = "gpt-4o"
    api_key_secret_arn  = "arn:aws:secretsmanager:..."
    azure_resource_name = "my-azure-openai-resource"
  }
}
```

Validation enforces this at the [variable level](variable-system.md).

## Validation Rules

| Rule | Error |
|------|-------|
| Provider must be one of 5 values | "Invalid AI provider" |
| API key required if not bedrock | "API key required for non-bedrock providers" |
| azure_resource_name required for azure-openai | "Azure resource name required" |
| Temperature: 0.0 - 2.0 | "Temperature out of range" |
| Thinking level: high, medium | "Invalid thinking level" |
