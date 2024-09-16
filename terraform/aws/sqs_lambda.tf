# SQS 큐 생성
resource "aws_sqs_queue" "enrollment_queue" {
  name = "EnrollmentQueue"
}

resource "aws_sqs_queue" "pre_enroll_queue" {
  name = "PreEnrollQueue"
}


# Lambda의 IAM Role 데이터 불러오기
data "aws_iam_role" "lambda_role" {
  name = "lambda_role"
}


# Lambda 함수: init_database_value.py
resource "aws_lambda_function" "init_database_value" {
    function_name = "init_database_value"
    role          = data.aws_iam_role.lambda_role.arn
    handler       = "init_database_value.lambda_handler"
    runtime       = "python3.9"
    s3_bucket     = "allcle-lambda-us"
    s3_key        = "lambda-code.zip"
}


# Lambda 함수: insert_into_enroll.py
resource "aws_lambda_function" "insert_into_enroll" {
  function_name = "insert_into_enroll"
  role          = data.aws_iam_role.lambda_role.arn
  handler       = "insert_into_enroll.lambda_handler"
  runtime       = "python3.9"
  
  s3_bucket     = "allcle-lambda-us"
  s3_key        = "lambda-code.zip"

  environment {
    variables = {
      DYNAMODB_TABLE = "Enrollment"
    }
  }
  depends_on = [ aws_lambda_function.init_database_value ]
}

# Lambda 함수: insert_into_pre.py
resource "aws_lambda_function" "insert_into_pre" {
    function_name = "insert_into_pre"
    role          = data.aws_iam_role.lambda_role.arn
    handler       = "insert_into_pre.lambda_handler"
    runtime       = "python3.9"

    s3_bucket     = "allcle-lambda-us"
    s3_key        = "lambda-code.zip"

    environment {
        variables = {
            DYNAMODB_TABLE = "PreEnroll"
        }
    }
    depends_on = [ aws_lambda_function.init_database_value ]
}

# Lambda 함수: pre_to_enroll.py
resource "aws_lambda_function" "pre_to_enroll" {
  function_name = "pre_to_enroll"
  role          = data.aws_iam_role.lambda_role.arn
  handler       = "pre_to_enroll.lambda_handler"
  runtime       = "python3.9"
  
  s3_bucket     = "allcle-lambda-us"
  s3_key        = "lambda-code.zip"

  environment {
    variables = {
      DYNAMODB_TABLE = "Enrollment"
    }
  }
  depends_on = [ aws_lambda_function.init_database_value ]
}

# Lambda 함수: dynamo_backup.py
resource "aws_lambda_function" "dynamo_backup" {
  function_name = "dynamo_backup"
  role = data.aws_iam_role.lambda_role.arn
  handler = "dynamo_backup.lambda_handler"
  runtime = "python3.9"
  s3_bucket = "allcle-lambda-us"
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