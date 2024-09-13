# DynamoDB 글로벌 테이블 생성
resource "aws_dynamodb_global_table" "Schedule" {
    depends_on = [
        aws_dynamodb_table.schedule_table,
        aws_dynamodb_table.course_table_us
    ]
    
    name = "Schedule"

    replica {
        region_name = "us-east-2"
    }

    replica {
        region_name = "ap-northeast-2"
    }

    lifecycle {
        ignore_changes = [ replica ]
    }
}

resource "aws_dynamodb_global_table" "Professor" {
    depends_on = [
        aws_dynamodb_table.professor_table,
        aws_dynamodb_table.professor_table_us
    ]
    
    name = "Professor"

    replica {
        region_name = "us-east-2"
    }

    replica {
        region_name = "ap-northeast-2"
    }

    lifecycle {
        ignore_changes = [ replica ]
    }
}

resource "aws_dynamodb_global_table" "Course" {
    depends_on = [
        aws_dynamodb_table.course_table,
        aws_dynamodb_table.course_table_us
    ]
    
    name = "Course"

    replica {
        region_name = "us-east-2"
    }

    replica {
        region_name = "ap-northeast-2"
    }

    lifecycle {
        ignore_changes = [ replica ]
    }
}

resource "aws_dynamodb_global_table" "Student" {
    depends_on = [
        aws_dynamodb_table.student_table,
        aws_dynamodb_table.student_table_us
    ]
    
    name = "Student"

    replica {
        region_name = "us-east-2"
    }

    replica {
        region_name = "ap-northeast-2"
    }

    lifecycle {
        ignore_changes = [ replica ]
    }
}

resource "aws_dynamodb_global_table" "Enrollment" {
    depends_on = [
        aws_dynamodb_table.enrollment_table,
        aws_dynamodb_table.enrollment_table_us
    ]
    
    name = "Enrollment"

    replica {
        region_name = "us-east-2"
    }

    replica {
        region_name = "ap-northeast-2"
    }

    lifecycle {
        ignore_changes = [ replica ]
    }
}

resource "aws_dynamodb_global_table" "PreEnroll" {
    depends_on = [
        aws_dynamodb_table.pre_enroll_table,
        aws_dynamodb_table.pre_enroll_table_us
    ]
    
    name = "PreEnroll"

    replica {
        region_name = "us-east-2"
    }

    replica {
        region_name = "ap-northeast-2"
    }

    lifecycle {
        ignore_changes = [ replica ]
    }
}