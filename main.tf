provider "aws" {
  region =var.aws_region
  access_key = ""
  secret_key = ""
}

provider "archive" {}
data "archive_file" "zip" {
  type        = "zip"
  source_file = "python/jsum.py"
  output_path = "python/jsum.zip"
}

### Lambda statements


data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    principals {
      identifiers = [
        "lambda.amazonaws.com",
        "sns.amazonaws.com",
        ]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "lambda_sns_policy" {
  name   = "lambda_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_policy.json
}


resource "aws_iam_role_policy_attachment" "lambda_sns_attach" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_sns_policy.arn
}

resource "aws_lambda_function" "lambda" {
  function_name = "jsum"
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  role    = aws_iam_role.iam_for_lambda.arn
  handler = "jsum.lambda_handler"
  runtime = "python3.8"
}


#### SNS statements

resource "aws_sns_topic" "send_email" {
  name = "send_email_topic"
}



data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"

  statement {
    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        6264-3882-2359,
      ]
    }

    effect = "Allow"


    # principals {
    #   type        = "AWS"
    #   identifiers = [
    #     "*"
    #     # aws_iam_role.iam_for_lambda.arn
    #   ]
    # }

    resources = [
      "*"
    ]

    sid = ""
  }
}

# resource "aws_sns_topic_policy" "sns_topic" {
#   arn = aws_sns_topic.send_email.arn

#   policy = data.aws_iam_policy_document.sns_topic_policy.json
# }

# resource "aws_iam_role" "iam_for_sns" {
#   name               = "iam_for_sns"
#   assume_role_policy = data.aws_iam_policy_document.sns_topic_policy.json
# }


resource "aws_sns_topic_subscription" "send_email_subscription" {
  for_each = toset(["kaufben.t@gmail.com"])
  topic_arn = aws_sns_topic.send_email.arn
  protocol = "email"
  endpoint = each.value
}