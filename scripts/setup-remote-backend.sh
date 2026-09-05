#!/bin/bash
set -e

# ==============================================================================
# Setup do Backend S3 Remoto para Terraform State
# Requisito: "Configure o Backend Remoto usando um Bucket S3 (e use_lockfile)"
# ==============================================================================

BUCKET_NAME=${1:-"togglemaster-terraform-state-fiap"}
REGION=${2:-"us-east-1"}

echo "Criando S3 Bucket para Terraform State: $BUCKET_NAME na região $REGION..."

if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Bucket $BUCKET_NAME já existe."
else
    if [ "$REGION" == "us-east-1" ]; then
        aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION"
    else
        aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" \
            --create-bucket-configuration LocationConstraint="$REGION"
    fi
    echo "Bucket $BUCKET_NAME criado com sucesso!"
fi

echo "Habilitando Versionamento no Bucket..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

echo "Habilitando Criptografia padrão (AES256)..."
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

echo "Bloqueando Acesso Público ao Bucket..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration '{
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }'

echo "=============================================================================="
echo "S3 Remote Backend configurado com sucesso!"
echo "Agora você pode executar 'terraform init' dentro da pasta terraform/."
echo "=============================================================================="
