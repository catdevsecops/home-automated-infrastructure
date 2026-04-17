variable "cluster_name" {
  description = "Talos / Kubernetes cluster name."
  type        = string

  validation {
    condition     = length(trim(var.cluster_name, " ")) > 0
    error_message = "cluster_name cannot be empty."
  }
}

variable "cluster_endpoint" {
  description = "Kubernetes API endpoint used in kubeconfig and machineconfig (e.g. https://192.168.1.201:6443)."
  type        = string
}

variable "talos_version" {
  description = "Talos version string"
  type        = string
  default     = "v1.12.6"
}

# ---------------------------------------------------------------------------
# Node definitions
# ---------------------------------------------------------------------------
variable "controlplane_nodes" {
  description = "Map of controlplane node name"
  type        = map(string)
}

variable "worker_nodes" {
  description = "Map of worker node name."
  type        = map(string)
}
