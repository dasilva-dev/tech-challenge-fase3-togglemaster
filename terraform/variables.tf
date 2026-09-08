variable "aws_region" {
  type        = string
  description = "Regiao AWS principal para provisionamento dos recursos"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Ambiente de execucao (ex: staging, prod, lab)"
  default     = "production"
}

variable "cluster_name" {
  type        = string
  description = "Nome do Cluster Kubernetes EKS"
  default     = "togglemaster-cluster"
}

variable "use_aws_academy" {
  type        = bool
  description = "Defina como true se estiver usando AWS Academy (utiliza LabRole). Defina como false para Conta Pessoal (cria IAM Roles completas)"
  default     = false
}

variable "vpc_cidr" {
  type        = string
  description = "Bloco CIDR da VPC"
  default     = "10.0.0.0/16"
}

variable "db_password" {
  type        = string
  description = "Senha de administrador dos bancos PostgreSQL"
  sensitive   = true
  default     = "ToggleMaster123"
}

variable "node_instance_types" {
  type        = list(string)
  description = "Tipos de instancias dos Worker Nodes EKS"
  default     = ["t3.small"]
}

variable "desired_nodes" {
  type        = number
  description = "Numero desejado de Worker Nodes no EKS"
  default     = 3
}

variable "install_argocd" {
  type        = bool
  description = "Instalar ArgoCD automaticamente via Helm no cluster"
  default     = true
}
