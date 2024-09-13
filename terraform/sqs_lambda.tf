# SQS 큐 생성

resource "aws_sqs_queue" "enrollment_queue" {
  name = "EnrollmentQueue"
}

resource "aws_sqs_queue" "pre_enroll_queue" {
  name = "PreEnrollQueue"
}

# Lambda의 SQS 풀 액세스 정책 생성
resource "aws_iam_policy" "sqs_policy" {
  name        = "sqs_policy"
  description = "SQS full access policy for Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "sqs:*",
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Lambda의 IAM Role 생성
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda의 DynamoDB 접근 풀 액세스 정책 생성
resource "aws_iam_policy" "dynamodb_policy" {
  name        = "dynamodb_policy"
  description = "DynamoDB full access policy for Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = "dynamodb:*",
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

# Lambda의 S3 Get/Put 액세스 정책 생성
resource "aws_iam_policy" "s3_policy" {
  name        = "s3_policy"
  description = "S3 Bucket read access policy for Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action  = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ],
        Effect   = "Allow",
        Resource = [
          "arn:aws:s3:::allcle-lambda/*"
          
        ]
      }
    ]
  })
}

# Lambda의 LogGroup, LogStream 생성 및 PutLogEvents를 허용 정책 생성
resource "aws_iam_policy" "lambda_logs_policy" {
  name = "lambda_logs_policy"
  description = "Create LogGroup & LogsStream, PutLogEvents access Policy for Lambda Functions"
  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          Resource = "*"
        }
      ]
    }
  )
}



# Lambda Role에 DynamoDBFullAccess, SQSFullAccess, S3Get/PutAccess, logsAccess 정책 연결
resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attachment" {
  policy_arn = aws_iam_policy.dynamodb_policy.arn
  role     = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_sqs_attachment" {
  policy_arn = aws_iam_policy.sqs_policy.arn
  role     = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_s3_attachment" {
  policy_arn = aws_iam_policy.s3_policy.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_iam_role_policy_attachment" "lambda_logs_attachment" {
  policy_arn = aws_iam_policy.lambda_logs_policy.arn
  role       = aws_iam_role.lambda_role.name
}

# Lambda 함수: init_database_value.py
resource "aws_lambda_function" "init_database_value" {
    function_name = "init_database_value"
    role          = aws_iam_role.lambda_role.arn
    handler       = "init_database_value.lambda_handler"
    runtime       = "python3.12"
    s3_bucket     = "allcle-lambda"
    s3_key        = "lambda-code.zip"
}


# Lambda 함수: insert_into_enroll.py
resource "aws_lambda_function" "insert_into_enroll" {
  function_name = "insert_into_enroll"
  role          = aws_iam_role.lambda_role.arn
  handler       = "insert_into_enroll.lambda_handler"
  runtime       = "python3.12"
  
  s3_bucket     = "allcle-lambda"
  s3_key        = "lambda-code.zip"

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.enrollment_table.name
    }
  }
  depends_on = [ aws_lambda_function.init_database_value ]
}

# Lambda 함수: insert_into_pre.py
resource "aws_lambda_function" "insert_into_pre" {
    function_name = "insert_into_pre"
    role          = aws_iam_role.lambda_role.arn
    handler       = "insert_into_pre.lambda_handler"
    runtime       = "python3.12"

    s3_bucket     = "allcle-lambda"
    s3_key        = "lambda-code.zip"

    environment {
        variables = {
            DYNAMODB_TABLE = aws_dynamodb_table.pre_enroll_table.name
        }
    }
    depends_on = [ aws_lambda_function.init_database_value ]
}

# Lambda 함수: pre_to_enroll.py
resource "aws_lambda_function" "pre_to_enroll" {
  function_name = "pre_to_enroll"
  role          = aws_iam_role.lambda_role.arn
  handler       = "pre_to_enroll.lambda_handler"
  runtime       = "python3.12"
  
  s3_bucket     = "allcle-lambda"
  s3_key        = "lambda-code.zip"

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.enrollment_table.name
    }
  }
  depends_on = [ aws_lambda_function.init_database_value ]
}

# Lambda 함수: dynamo_backup.py
resource "aws_lambda_function" "dynamo_backup" {
  function_name = "dynamo_backup"
  role = aws_iam_role.lambda_role.arn
  handler = "dynamo_backup.lambda_handler"
  runtime = "python3.12"
  s3_bucket = "allcle-lambda"
  s3_key = "lambda-code.zip"

  depends_on = [ aws_lambda_function.init_database_value ]
}

  # Enrollment SQS Trigger 추가
resource "aws_lambda_event_source_mapping" "enroll_sqs_trigger" {
  event_source_arn = aws_sqs_queue.enrollment_queue.arn
  function_name = aws_lambda_function.insert_into_enroll.function_name
  enabled          = true
  batch_size       = 10

  depends_on = [ aws_sqs_queue.enrollment_queue, aws_lambda_function.insert_into_enroll ]
}

# Pre Enrollment SQS Trigger 추가
resource "aws_lambda_event_source_mapping" "pre_enroll_sqs_trigger" {
  event_source_arn = aws_sqs_queue.pre_enroll_queue.arn
  function_name = aws_lambda_function.insert_into_pre.function_name
  enabled          = true
  batch_size       = 10

  depends_on = [ aws_sqs_queue.pre_enroll_queue, aws_lambda_function.pre_to_enroll ]
}

# EventBridge 규칙 생성
resource "aws_cloudwatch_event_rule" "backup_schedule" {
  name = "daily_call_dynamo_backup_lambda"
  description = "daily call to DynamoDB backup lambda"
  schedule_expression = "cron(0 15 * * ? *)" # 백업 주기(매일 KST 00:00 = UTC 15:00 )
  # AWS는 UTC 기준으로 시간을 지정해주어야 한다.
}

# EventBridge 대상 생성
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule = aws_cloudwatch_event_rule.backup_schedule.name
  target_id = "DynamoDBBackupTarget"
  arn = aws_lambda_function.dynamo_backup.arn

  # 유연한 기간 설정 (5분)
  retry_policy {
    maximum_event_age_in_seconds = 300 # 최대 5분
    maximum_retry_attempts       = 1 # 재시도 횟수 설정
  }
}

# Lambda 권한 부여 (EventBridge에 의해 트리거 가능하도록)
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id = "AllowExecutionFromEventBridge"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dynamo_backup.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.backup_schedule.arn
}