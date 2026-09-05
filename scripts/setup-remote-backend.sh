#!/bin/bash
set -e

# ==============================================================================
# Setup do Backend S3 Remoto para Terraform State
# Permite ao usuário escolher interativamente qual perfil AWS utilizar
# ==============================================================================

select_aws_profile() {
    AVAILABLE_PROFILES=($(aws configure list-profiles 2>/dev/null || true))
    
    if [ ${#AVAILABLE_PROFILES[@]} -eq 0 ]; then
        echo "Nenhum perfil AWS encontrado na máquina. Execute 'aws configure' para configurar suas credenciais."
        exit 1
    elif [ ${#AVAILABLE_PROFILES[@]} -eq 1 ]; then
        export AWS_PROFILE="${AVAILABLE_PROFILES[0]}"
        echo ">> Usando o único perfil AWS configurado: $AWS_PROFILE"
    else
        echo "=============================================================================="
        echo "Perfis AWS configurados nesta máquina:"
        for i in "${!AVAILABLE_PROFILES[@]}"; do
            echo "  [$((i+1))] ${AVAILABLE_PROFILES[$i]}"
        done
        echo "=============================================================================="
        
        while true; do
            read -p "Escolha o número do perfil desejado [1-${#AVAILABLE_PROFILES[@]}]: " CHOICE
            if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [ "$CHOICE" -ge 1 ] && [ "$CHOICE" -le "${#AVAILABLE_PROFILES[@]}" ]; then
                export AWS_PROFILE="${AVAILABLE_PROFILES[$((CHOICE-1))]}"
                echo ">> Perfil selecionado: $AWS_PROFILE"
                break
            else
                echo "Opção inválida. Digite um número entre 1 e ${#AVAILABLE_PROFILES[@]}."
            fi
        done
    fi

    # Validação rápida de credenciais
    echo ">> Validando credenciais do perfil '$AWS_PROFILE'..."
    IDENTITY=$(aws sts get-caller-identity --output json 2>/dev/null || true)
    if [ -z "$IDENTITY" ]; then
        echo "ERRO: As credenciais do perfil '$AWS_PROFILE' são inválidas ou expiraram."
        echo "Dica: Se for AWS Academy, atualize o AWS_SESSION_TOKEN em ~/.aws/credentials."
        exit 1
    else
        ACCOUNT=$(echo "$IDENTITY" | grep -o '"Account": "[^"]*' | cut -d'"' -f4)
        ARN=$(echo "$IDENTITY" | grep -o '"Arn": "[^"]*' | cut -d'"' -f4)
        echo ">> Autenticado com sucesso na AWS! Conta: $ACCOUNT ($ARN)"
    fi
}

select_aws_profile

BUCKET_NAME=${1:-"togglemaster-state-${ACCOUNT}"}
REGION=${2:-"us-east-1"}

echo ""
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
echo "S3 Remote Backend configurado com sucesso com o perfil '$AWS_PROFILE'!"
echo "Agora você pode executar 'export AWS_PROFILE=$AWS_PROFILE' e rodar o Terraform."
echo "=============================================================================="
