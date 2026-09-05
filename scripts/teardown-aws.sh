#!/bin/bash
set -e

# ==============================================================================
# Script de Destruição Completa da Infraestrutura AWS (Teardown)
# Tech Challenge Fase 3 - ToggleMaster
# ==============================================================================

REGION=${AWS_REGION:-"us-east-1"}
CLUSTER_NAME="togglemaster-cluster"
STATE_BUCKET="togglemaster-terraform-state-fiap"
ECR_REPOS=(
  "togglemaster/auth-service"
  "togglemaster/flag-service"
  "togglemaster/targeting-service"
  "togglemaster/evaluation-service"
  "togglemaster/analytics-service"
)

echo "=============================================================================="
echo "                   TOGGLEMASTER - AWS TEARDOWN COMPLETO"
echo "=============================================================================="
echo "ATENÇÃO: Este script irá DESTRUIR TODOS os recursos criados na AWS:"
echo "  - Ingress Controllers & Load Balancers (ELB/ALB)"
echo "  - Imagens nos 5 Repositórios ECR"
echo "  - Cluster EKS e Worker Nodes"
echo "  - 3 Instâncias RDS PostgreSQL"
echo "  - Cluster ElastiCache Redis"
echo "  - Tabela DynamoDB"
echo "  - Fila SQS e DLQ"
echo "  - VPC, Subnets, NAT Gateway e Security Groups"
echo "=============================================================================="

if [ "$1" != "--force" ]; then
    read -p "Tem certeza absoluta que deseja destruir toda a infraestrutura? (digite 'sim' para confirmar): " CONFIRM
    if [ "$CONFIRM" != "sim" ]; then
        echo "Operação cancelada pelo usuário."
        exit 0
    fi
fi

echo ""
echo ">> 1. Removendo Ingress e Load Balancers do Kubernetes para liberar os ALBs/ELBs da VPC..."
if command -v kubectl &> /dev/null && kubectl get svc -A &> /dev/null; then
    echo "Cluster EKS acessível. Deletando LoadBalancers e Ingress..."
    kubectl delete ingress --all -A --ignore-not-found=true --timeout=60s || true
    kubectl delete svc -n ingress-nginx --all --ignore-not-found=true --timeout=60s || true
    kubectl delete svc -n argocd -l app.kubernetes.io/name=argocd-server --ignore-not-found=true --timeout=60s || true
    echo "Aguardando 15 segundos para liberação dos ELBs na AWS..."
    sleep 15
else
    echo "Cluster EKS não conectado ou já inacessível. Prosseguindo..."
fi

echo ""
echo ">> 2. Esvaziando imagens dos 5 repositórios ECR..."
for repo in "${ECR_REPOS[@]}"; do
    if aws ecr describe-repositories --repository-names "$repo" --region "$REGION" &> /dev/null; then
        echo "Limpando imagens de $repo..."
        IMAGE_IDS=$(aws ecr list-images --repository-name "$repo" --region "$REGION" --query 'imageIds[*]' --output json)
        if [ "$IMAGE_IDS" != "[]" ] && [ -n "$IMAGE_IDS" ]; then
            aws ecr batch-delete-image --repository-name "$repo" --image-ids "$IMAGE_IDS" --region "$REGION" > /dev/null || true
            echo "Imagens de $repo removidas."
        fi
    fi
done

echo ""
echo ">> 3. Executando 'terraform destroy'..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

cd "$TERRAFORM_DIR"
if [ -d ".terraform" ]; then
    terraform destroy -auto-approve
else
    echo "Inicializando terraform antes da destruição..."
    terraform init -backend=false || true
    terraform destroy -auto-approve
fi

echo ""
echo ">> 4. Destruição do Bucket S3 de Remote State (Opcional)..."
if [ "$1" == "--delete-state-bucket" ] || [ "$2" == "--delete-state-bucket" ]; then
    echo "Esvaziando e deletando bucket S3: $STATE_BUCKET..."
    if aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null; then
        aws s3 rb "s3://$STATE_BUCKET" --force
        echo "Bucket S3 $STATE_BUCKET excluído."
    fi
else
    echo "Nota: O bucket S3 de estado ($STATE_BUCKET) foi preservado."
    echo "Para deletá-lo também, execute: $0 --force --delete-state-bucket"
fi

echo ""
echo "=============================================================================="
echo ">> TEARDOWN CONCLUÍDO COM SUCESSO! Todos os recursos foram removidos da AWS."
echo "=============================================================================="
