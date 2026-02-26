resource "aws_dynamodb_table" "this" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = var.hash_key
  range_key      = var.range_key

  attribute {
    name = var.hash_key
    type = "S"
  }

  dynamic "attribute" {
    for_each = var.range_key != null ? [1] : []
    content {
      name = var.range_key
      type = "S"
    }
  }

  dynamic "attribute" {
    for_each = var.gsi_hash_key != null ? [1] : []
    content {
      name = var.gsi_hash_key
      type = "S"
    }
  }

  dynamic "ttl" {
    for_each = var.ttl_enabled ? [1] : []
    content {
      enabled        = true
      attribute_name = var.ttl_attribute
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.gsi_name != null && var.gsi_hash_key != null ? [1] : []
    content {
      name            = var.gsi_name
      hash_key        = var.gsi_hash_key
      projection_type = "ALL"
    }
  }

  tags = var.tags
}
