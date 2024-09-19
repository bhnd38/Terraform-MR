# DynamoDB 글로벌 테이블 생성
resource "aws_dynamodb_global_table" "schedule_table" {
    depends_on = [ aws_dynamodb_table.schedule_table ]
    
    name = "Schedule"

    replica {
        region_name = "ap-northeast-2"
    }

    replica {
        region_name = "us-east-2"
    }

    lifecycle {
        ignore_changes = [ replica ]
    }
}

resource "aws_dynamodb_global_table" "professor_table" {
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

resource "aws_dynamodb_global_table" "course_table" {
    depends_on = [
        aws_dynamodb_table.course_table
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

resource "aws_dynamodb_global_table" "student_table" {
    depends_on = [
        aws_dynamodb_table.student_table
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

resource "aws_dynamodb_global_table" "enrollment_table" {
    depends_on = [
        aws_dynamodb_table.enrollment_table
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

resource "aws_dynamodb_global_table" "pre_enroll_table" {
    depends_on = [
        aws_dynamodb_table.pre_enroll_table
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