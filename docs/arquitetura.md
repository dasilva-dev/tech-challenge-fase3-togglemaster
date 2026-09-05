# Arquitetura de Infraestrutura em Nuvem (AWS) - ToggleMaster Fase 3

Este documento detalha a arquitetura em nuvem provisionada de forma 100% automatizada e declarativa através do **Terraform**, atendendo aos requisitos do Tech Challenge da Fase 3 (FIAP Pós-Tech) com foco em viabilidade de custos (**Ambiente Principal 100% Free Tier**) e flexibilidade corporativa (**Arquitetura Completa Multi-Recurso**).

---

## 1. Ambiente Principal: Arquitetura 100% Free Tier (Custo Zero)

Para garantir que o projeto possa ser executado e validado em contas da AWS sem gerar cobranças financeiras, o ambiente principal foi estruturado para utilizar exclusivamente recursos do **AWS Free Tier (nível gratuito)**.

```
+----------------------------------------------------------------------------------------------------+
| AWS Cloud (us-east-1) - VPC: 10.0.0.0/16 [Modo Free Tier: Custo Zero]                              |
|                                                                                                    |
|  [ Internet Gateway (IGW) ]                                                                        |
|         |                                                                                          |
|  [ Public Subnet: 10.0.1.0/24 ]                                                                    |
|         |                                                                                          |
|   +-----v---------------------------------------------------------------------------------------+  |
|   | Instância EC2 Free Tier: t3.micro (750 horas/mês gratuitas)                                 |  |
|   | Sistema Operacional: Ubuntu 24.04 LTS                                                       |  |
|   |                                                                                             |  |
|   |  Ambiente de Execução (Docker Compose / K3s):                                               |  |
|   |    - [ auth-service ]       (Go)     : Porta 8001                                           |  |
|   |    - [ flag-service ]       (Python) : Porta 8002                                           |  |
|   |    - [ targeting-service ]  (Python) : Porta 8003                                           |  |
|   |    - [ evaluation-service ] (Go)     : Porta 8004                                           |  |
|   |    - [ analytics-service ]  (Python) : Porta 8005                                           |  |
|   |    - [ Redis Container ]    (Cache local na EC2 para avaliação)                             |  |
|   +---------------------------------------------------------------------------------------------+  |
|         |                                                                                          |
|  [ Database Subnets: 10.0.20.0/24, 10.0.21.0/24 ]                                                  |
|         |                                                                                          |
|   +-----v---------------------------------------------------------------------------------------+  |
|   | 1x Instância Amazon RDS PostgreSQL: db.t3.micro (750 horas/mês + 20 GB gp3 gratuitos)       |  |
|   | Contém os bancos relacionais: 'authdb', 'flagdb' e 'targetingdb'                            |  |
|   +---------------------------------------------------------------------------------------------+  |
|                                                                                                    |
|  Serviços AWS Gerenciados no Nível Gratuito:                                                       |
|    - Amazon DynamoDB: Tabela 'ToggleMasterAnalytics' (25 GB gratuitos forever)                     |
|    - Amazon SQS: Fila 'ToggleMasterEvents' (1 milhão de requisições gratuitas forever)             |
|    - Amazon ECR: 5 Repositórios privados (500 MB gratuitos/mês)                                    |
|    - Amazon S3: Remote State Bucket com use_lockfile = true (5 GB gratuitos)                       |
+----------------------------------------------------------------------------------------------------+
```

### Otimizações do Modo Free Tier:
1. **Sem NAT Gateway**: Elimina o custo fixo de ~$34.50/mês do NAT Gateway, utilizando rotas diretas via Internet Gateway com Security Groups estritamente configurados.
2. **1 Instância RDS PostgreSQL**: A cota do Free Tier permite 750 horas de RDS Single-AZ `db.t3.micro`. Uma única instância atende a persistência dos microsserviços sem ultrapassar a franquia.
3. **Redis Local em Contêiner**: Evita o custo de cluster dedicado do ElastiCache, mantendo a latência mínima em memória na própria instância EC2.
4. **Instância EC2 `t3.micro`**: 750 horas mensais cobertas pelo Free Tier, provisionada automaticamente com Docker e Docker Compose via User Data.

---

## 2. Arquitetura Completa Enterprise (EKS Multi-Recurso)

A arquitetura corporativa completa desenvolvida para a entrega acadêmica original está preservada e disponível no diretório:
📁 **[`arquitetura-completa/`](../arquitetura-completa/)**

Ela contempla:
- **Cluster Amazon EKS v1.30** com Managed Node Groups (`t3.small`).
- **3 Instâncias RDS PostgreSQL independentes** para cada domínio de serviço.
- **Cluster Amazon ElastiCache Redis** gerenciado pela AWS.
- **ArgoCD Controller** instalado via Helm para GitOps automatizado.
- **NAT Gateway e Subnets Privadas** isoladas para os nós do Kubernetes.

Para alternar entre os ambientes no Terraform:
- **Ambiente Free Tier (Padrão)**: `enable_free_tier = true` em `terraform.tfvars`.
- **Ambiente EKS Completo**: `enable_free_tier = false` em `terraform.tfvars` (ou executar a partir de `arquitetura-completa/terraform/`).

---

## 3. Segurança e Isolamento

Independentemente do modo de execução:
- **Security Groups**: O banco de dados PostgreSQL aceita conexões apenas originadas do Security Group de aplicação.
- **Armazenamento de Senhas**: As credenciais nunca ficam hardcoded no código fonte, sendo injetadas via variáveis sensíveis no Terraform ou Secrets no ambiente.
- **Backend Remoto**: O estado do Terraform é gravado no Amazon S3 com criptografia AES-256 e controle de concorrência ativado via `use_lockfile = true`.
