# Roteiro Completo de Gravação de Vídeo - Tech Challenge Fase 3 (Nota Máxima)

> **Tempo total estimado**: 10 a 15 minutos (limite máximo permitido: 20 minutos).  
> **Objetivo**: Demonstrar de forma prática e incontestável o funcionamento da Infraestrutura como Código (Terraform), Pipeline DevSecOps (GitHub Actions com bloqueio), GitOps e ArgoCD sincronizando no Amazon EKS.

---

## 🟢 1. Introdução e Contexto (1 minuto)

### 🎙️ O que falar:
> *"Olá professor e avaliadores! Neste vídeo apresentamos o projeto do Tech Challenge da Fase 3: Automação e Segurança na Nuvem.  
> Na Fase 2, tínhamos os 5 microsserviços do ToggleMaster provisionados manualmente. Agora, na Fase 3, implementamos o princípio 'se não está no código, não existe':  
> 1. Infraestrutura 100% como Código com Terraform modular e Backend S3;  
> 2. Pipelines de CI com DevSecOps no GitHub Actions com verificações de Linter, SAST, SCA e Container Scan com bloqueio de vulnerabilidades críticas;  
> 3. Entrega Contínua baseada em GitOps utilizando ArgoCD sincronizado com o Amazon EKS."*

---

## 🌐 2. Infraestrutura como Código (Terraform) (3 a 4 minutos)

### 👉 O que mostrar na tela:
1. **VS Code / Editor**: Abra a pasta `terraform/`.
   - Mostre os módulos: `networking`, `eks`, `databases`, `messaging`, `ecr`, `argocd`.
   - Mostre o arquivo `backend.tf` configurado com S3 Remote State e a flag `use_lockfile = true`.
2. **Terminal (WSL Ubuntu)**:
   - Execute:
     ```bash
     cd terraform
     terraform plan
     ```
   - Destaque que todos os recursos estão mapeados declarativamente.
3. **Console AWS**:
   - **VPC & Subnets**: Mostre a VPC `togglemaster-cluster-vpc` com subnets públicas, privadas e de banco.
   - **Amazon EKS**: Mostre o cluster `togglemaster-cluster` ativo e o Node Group de nós gerenciados.
   - **Amazon RDS**: Mostre as 3 instâncias PostgreSQL (`togglemaster-db-auth`, `togglemaster-db-flag`, `togglemaster-db-targeting`).
   - **ElastiCache**: Mostre o cluster Redis `togglemaster-cache`.
   - **Amazon DynamoDB**: Mostre a tabela `ToggleMasterAnalytics`.
   - **Amazon SQS**: Mostre a fila `ToggleMasterEvents` e sua DLQ.
   - **Amazon ECR**: Mostre os 5 repositórios criados com Image Scanning habilitado.

### 🎙️ O que falar:
> *"Toda a infraestrutura foi construída de forma modular no Terraform. Eliminamos qualquer ação manual no console. Os bancos e o cache Redis estão em subnets isoladas, com regras de Security Group que autorizam conexões somente a partir dos nós do EKS. O estado da infraestrutura está protegido em um bucket S3 com versionamento e locking nativo."*

---

## 🔐 3. Pipeline DevSecOps: Demonstração da Falha e Correção (4 a 5 minutos)

> 🔥 **Esta é uma das partes mais pontuadas da avaliação!**

### 👉 O que mostrar na tela:
1. **Terminal**:
   - Execute o script de injeção de vulnerabilidade:
     ```bash
     bash scripts/simulate-security-fail.sh fail
     ```
   - Mostre que foi adicionada uma versão antiga e vulnerável no `services/flag-service/requirements.txt` (`urllib3==1.24.1`).
   - Faça o commit e push:
     ```bash
     git commit -am "test: inject vulnerable dependency for devsecops demo"
     git push origin main
     ```
2. **GitHub Actions**:
   - Abra a aba **Actions** no repositório.
   - Mostre o workflow do `flag-service` sendo acionado.
   - Abra o job **3. Security Scan (SCA & SAST)**.
   - **Mostre o pipeline FALHANDO em vermelho**: o Trivy detectou a CVE crítica e aplicou a regra de bloqueio (`exit-code 1`), impedindo o build da imagem Docker e o envio ao ECR.
3. **Terminal**:
   - Execute a correção:
     ```bash
     bash scripts/simulate-security-fail.sh fix
     git commit -am "fix: remove vulnerable dependency"
     git push origin main
     ```
4. **GitHub Actions**:
   - Acompanhe a nova execução:
   - ✅ Build & Unit Test: Passou
   - ✅ Linter (Flake8): Passou
   - ✅ SCA & SAST (Trivy & Bandit): Passou
   - ✅ Docker Build & Container Scan: Passou
   - ✅ ECR Push: Imagem enviada com a tag do commit hash
   - ✅ GitOps Auto-Update: Manifesto atualizado no Git

### 🎙️ O que falar:
> *"Aqui demonstramos o conceito de Shift-Left Security e Política de Bloqueio. Quando um desenvolvedor tenta subir uma biblioteca com vulnerabilidade crítica conhecida, o scanner SCA bloqueia imediatamente a pipeline. A imagem vulnerável nunca chega a ser criada nem enviada ao ECR. Após aplicarmos a correção, o pipeline avança com sucesso por todos os estágios de validação e segurança."*

---

## 🚀 4. GitOps e ArgoCD em Ação (3 a 4 minutos)

### 👉 O que mostrar na tela:
1. **GitHub**:
   - Abra o arquivo `gitops/apps/flag-service/deployment.yaml`.
   - Mostre o commit automático gerado pelo bot do GitHub Actions com a nova tag da imagem (`v1.0.0-xxxxxxx`).
2. **Interface Web do ArgoCD**:
   - Acesse a interface do ArgoCD no navegador.
   - Mostre as aplicações dos 5 microsserviços:
     - `togglemaster-auth-service`
     - `togglemaster-flag-service`
     - `togglemaster-targeting-service`
     - `togglemaster-evaluation-service`
     - `togglemaster-analytics-service`
   - Mostre o status verde (`Healthy` e `Synced`).
   - Mostre o ArgoCD detectando a mudança de commit no repositório e realizando a sincronização automática (*auto-sync*) no cluster EKS sem qualquer intervenção manual.
3. **Terminal**:
   - Mostre os pods rodando no namespace `togglemaster`:
     ```bash
     kubectl get pods -n togglemaster
     ```
   - Mostre que a imagem do pod corresponde à nova tag gerada pelo pipeline.

### 🎙️ O que falar:
> *"No modelo GitOps, abandonamos completamente o push direto via CI. O pipeline apenas atualiza o arquivo deployment.yaml no Git. O ArgoCD monitora o repositório como fonte única da verdade e sincroniza automaticamente a nova versão para o cluster EKS de forma declarativa e com capacidade de auto-recuperação (self-healing)."*

---

## 🧪 5. Validação Funcional dos Endpoints (2 minutos)

### 👉 O que mostrar na tela:
1. **Postman ou Navegador / Terminal**:
   - Teste de saúde da API:
     - `GET http://<INGRESS_OR_LB_IP>/flags/health` -> Retorna `{"status": "ok"}`
   - Consulta de flags:
     - `GET http://<INGRESS_OR_LB_IP>/flags`
   - Criação de uma flag (POST `/flags`):
     ```json
     {
       "name": "DEMO_FASE3_GITOPS",
       "description": "Validando Fase 3 com GitOps e ArgoCD",
       "is_enabled": true
     }
     ```
   - Avaliação da flag (`GET http://<INGRESS_OR_LB_IP>/eval/evaluate?user_id=123&flag_name=DEMO_FASE3_GITOPS`):
     - Mostra retorno `{"result": true}`.

### 🎙️ O que falar:
> *"Com isso comprovamos que toda a cadeia está operacional: a requisição entra pelo Ingress, atinge os microsserviços no EKS, consulta o cache Redis e os bancos RDS PostgreSQL, e os eventos são publicados no SQS e gravados no DynamoDB."*

---

## 🏁 6. Conclusão (30 segundos a 1 minuto)

### 🎙️ O que falar:
> *"Concluímos com êxito todos os entregáveis do Tech Challenge da Fase 3: infraestrutura imutável e modular com Terraform, governança de segurança Shift-Left com bloqueio de vulnerabilidades críticas via DevSecOps, e entrega contínua moderna e resiliente com GitOps e ArgoCD. Muito obrigado!"*

---

## 📋 Checklist de Gravação:
- [ ] Terraform plan/apply e recursos no console AWS
- [ ] Simulação de falha proposital no pipeline (Trivy bloqueando)
- [ ] Correção e pipeline passando 100%
- [ ] Atualização automática do manifesto no GitOps
- [ ] Interface do ArgoCD com os 5 serviços saudáveis e sincronizados
- [ ] Teste no Postman ou curl comprovando a aplicação ativa
