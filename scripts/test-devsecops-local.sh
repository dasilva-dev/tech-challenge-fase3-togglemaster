#!/bin/bash
set -e

# ==============================================================================
# Execução Local de Testes e Scans DevSecOps (WSL Ubuntu)
# ==============================================================================

echo "=================================================="
echo "1. Rodando Testes Unitários Go"
echo "=================================================="
cd services/auth-service && go test -v ./...
cd ../evaluation-service && go test -v ./...
cd ../..

echo "=================================================="
echo "2. Rodando Testes Unitários Python"
echo "=================================================="
python3 -m unittest discover -s services/flag-service -p 'test_*.py'
python3 -m unittest discover -s services/targeting-service -p 'test_*.py'
python3 -m unittest discover -s services/analytics-service -p 'test_*.py'

echo "=================================================="
echo "3. Validando Terraform Syntax e Módulos"
echo "=================================================="
cd terraform
terraform fmt -check -recursive
terraform validate
cd ..

echo "=================================================="
echo "Todos os testes e validações locais passaram!"
echo "=================================================="
