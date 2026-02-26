variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "hash_key" {
  description = "Hash key (partition key) for the table"
  type        = string
}

variable "range_key" {
  description = "Range key (sort key) for the table"
  type        = string
  default     = null
}

variable "ttl_enabled" {
  description = "Enable TTL for the table"
  type        = bool
  default     = false
}

variable "ttl_attribute" {
  description = "Attribute name for TTL"
  type        = string
  default     = "ttl"
}

variable "gsi_name" {
  description = "Name of the Global Secondary Index"
  type        = string
  default     = null
}

variable "gsi_hash_key" {
  description = "Hash key for the GSI"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the table"
  type        = map(string)
  default     = {}
}
