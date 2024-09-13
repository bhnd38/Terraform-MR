# DynamoDB 테이블 생성

resource "aws_dynamodb_table" "schedule_table" {
    name           = "Schedule"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "course_id"
    stream_enabled = true
    stream_view_type = "NEW_AND_OLD_IMAGES"

    attribute {
        name = "course_id"
        type = "N"
    }

    attribute {
        name = "day"
        type = "S"
    }

    global_secondary_index {
        name               = "DayIndex"
        hash_key           = "day"
        projection_type    = "ALL"
        range_key = "course_id"
    }

}

resource "aws_dynamodb_table" "professor_table" {
    name           = "Professor"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "prof_id"
    stream_enabled = true
    stream_view_type = "NEW_AND_OLD_IMAGES"
    
    attribute {
        name = "prof_id"
        type = "N"
    }
}

resource "aws_dynamodb_table" "course_table" {
    name           = "Course"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "course_id"
    stream_enabled = true
    stream_view_type = "NEW_AND_OLD_IMAGES"

    attribute {
        name = "course_id"
        type = "N"
    }

}

resource "aws_dynamodb_table" "student_table" {
    name           = "Student"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "stu_id"
    stream_enabled = true
    stream_view_type = "NEW_AND_OLD_IMAGES"

    attribute {
        name = "stu_id"
        type = "N"
    }

}

resource "aws_dynamodb_table" "enrollment_table" {
    name           = "Enrollment"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "enroll_id"
    stream_enabled = true
    stream_view_type = "NEW_AND_OLD_IMAGES"

    attribute {
        name = "enroll_id"
        type = "N"
    }

    attribute {
        name = "course_id"
        type = "N"
    }
    
    attribute {
        name = "stu_id"
        type = "N"
    }

    global_secondary_index {
        name               = "student-course-index"
        hash_key           = "stu_id"
        range_key          = "course_id"
        projection_type    = "ALL"
    }

}

resource "aws_dynamodb_table" "pre_enroll_table" {
    name           = "PreEnroll"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "enroll_id"
    stream_enabled = true
    stream_view_type = "NEW_AND_OLD_IMAGES"

    attribute {
        name = "enroll_id"
        type = "N"
    }

    attribute {
        name = "course_id"
        type = "N"
    }

    attribute {
        name = "stu_id"
        type = "N"
    }

    global_secondary_index {
        name               = "student-course-index"
        hash_key           = "stu_id"
        range_key          = "course_id"
        projection_type    = "ALL"
        
    }

}

