variable "resource_group_name" {
    type = string 
}

variable "location" { 
    type = string
}

variable "env" {
    type = string
}

variable "instance_count" {
	type    = any
	default = 6
}
variable "vm_size" { 
    type    = string
    default = "Standard_D2s_v5" 
}

variable "admin_username" { 
    type    = string
    default = "azureuser"
}

variable "ssh_public_key" { 
    type = string 
}

variable "golden_image_id" { 
    type = string
    default = ""
}

variable "web_subnet_id" { 
    type = string
}

variable "nsg_web_id" { 
    type = string
}

variable "tags" { 
    type    = map(string)
    default = {}
}

variable "lb_pool_id" { 
    type = string
}
