# Learning Journal

Este journal documenta a história do repositório até o commit `567dab9`, que é o
`HEAD` gravado no momento desta edição.

## Como este journal usa evidências

- Base primária:
  `git log`, `README.md`, `openapi.yaml`, `docs/architecture/overview.md`,
  services de `sandbox/*` e `security/*`, além dos testes de integração, sistema
  e contrato.

- Quando o texto fala de “sandbox sério”:
  a expressão se ancora em isolamento, consent lifecycle, webhook delivery e
  quality gates que aparecem no histórico, não em promessa regulatória.

- Escopo:
  commits já gravados até `567dab9`.

## O que o histórico não prova

- O histórico não prova conformidade regulatória completa de Open Finance.
- Ele não prova certificação FAPI/OIDC real.
- Ele não prova relacionamento com parceiros bancários de verdade.

## 1. Objetivo do projeto

OpenBank Sandbox existe para ensinar como modelar um ambiente de integração
bancária que seja local, auditável e útil para parceiros sem fingir que é o
sistema bancário real. O que o repo quer deixar claro é:

- consentimento é um aggregate central, não detalhe de autenticação;
- bearer token e app credential têm papeis diferentes;
- payment initiation e webhook replay exigem contrato e estado;
- `/ops` existe porque alguém precisa operar cenários, auditoria e replays.

Ao terminar este journal, o leitor deve conseguir:

- seguir um parceiro de `DeveloperApp` até `Consent`, `AccessToken` e
  `PaymentInitiation`;
- explicar por que o sandbox simula fluxo e falha, e não só endpoint feliz;
- apontar onde isolamento, rate limiting e webhook replay são protegidos;
- dizer que partes do repo ensinam integração realista e que partes continuam
  fora de escopo por honestidade.

## 2. Como ler o repositório primeiro, em ordem de aprendizado

1. Leia `README.md` e `openapi.yaml`.
2. Leia `docs/architecture/overview.md`.
3. Leia `app/controllers/api_controller.rb` e depois os serviços de segurança:
   `app/services/security/client_authenticator.rb`,
   `app/services/security/token_authenticator.rb`,
   `app/services/security/authorizer.rb`.
4. Leia `app/services/sandbox/consent_creator.rb`,
   `app/services/sandbox/token_issuer.rb` e
   `app/services/sandbox/payment_initiator.rb`.
5. Leia `app/services/sandbox/webhook_http_client.rb`,
   `app/services/sandbox/webhook_endpoint_policy.rb` e
   `app/services/sandbox/partner_event.rb`.
6. Leia `app/controllers/ops/consents_controller.rb`,
   `app/controllers/ops/payments_controller.rb` e
   `app/controllers/ops/webhook_deliveries_controller.rb`.
7. Feche com os testes:
   `test/integration/openfinance_partner_flow_test.rb`,
   `test/integration/authorization_and_isolation_test.rb`,
   `test/integration/openapi_response_contract_test.rb`,
   `test/system/ops_console_test.rb`.

### O que ignorar na primeira passada

- Não comece por backup tooling e alerting.
  Primeiro entenda consentimento, token e pagamento.

- Não trate webhook como detalhe tardio.
  Neste sandbox, replay e assinatura fazem parte da lição principal.

## 3. História cronológica da implementação

### Fase 1: shell híbrido e domínio do sandbox (`4fec496` a `37223dc`, 2026-05-29)

- O repositório nasceu praticamente pronto para ensinar o fluxo completo:
  documentação, shell Rails híbrido, agregados do sandbox, security services,
  endpoints versionados, console ops e cobertura Minitest.
- Isso mostra uma escolha madura de escopo: o produto queria simular onboarding,
  consentimento e pagamento como sistema, não como endpoints isolados.
- Base usada:
  commits `4fec496`, `1e4ce39`, `0857514`, `27ce9fb`, `01e626d`, `9ab1940`,
  `6d61465`, `37223dc`.

### Fase 2: benchmark, docs e quality gate (`be22296` a `77353ba`, 2026-05-29)

- Entraram benchmark, produção-readiness docs, workflow de CI e aprofundamento de
  consent/event guidance.
- A tese aqui é clara: até sandbox precisa ser tratado como produto operável.
- Base usada:
  commits `be22296`, `cdcdf52`, `d4b2a6e`, `77353ba`.

### Fase 3: contratos de webhook e endurecimento de produção local (`b71ce30` a `567dab9`, 2026-05-30 a 2026-05-31)

- O trecho recente do histórico é sobre honestidade operacional.
- `b71ce30` alinha eventos do webhook aos contratos v1.
- `7b52add`, `d53fcf9`, `18ee896` e `567dab9` apertam readiness, egress seguro,
  replay signature e rotação de credenciais.
- `c9bee45`, `fb04622` e `6be8b9f` mostram o padrão de specialist: não basta
  dizer que existe webhook; é preciso provar entrega HTTP real, schema público e
  event contracts.
- Base usada:
  commits `b71ce30`, `7b52add`, `d53fcf9`, `c9bee45`, `fb04622`, `18ee896`,
  `6be8b9f`, `567dab9`.

## Features importantes como unidades completas

### Consentimento, token e pagamento como sequência explícita

- Problema que resolve:
  em Open Finance, autorização, autenticação e comando financeiro não podem ser
  a mesma abstração.

- Commits principais:
  `0857514`, `27ce9fb`, `01e626d`.

- Arquivos principais:
  `app/services/sandbox/consent_creator.rb`,
  `app/services/sandbox/token_issuer.rb`,
  `app/services/sandbox/payment_initiator.rb`,
  `app/models/consent.rb`,
  `app/models/payment_initiation.rb`.

- Por que a solução final tomou essa forma:
  o repo prefere explicitar a cadeia consent -> token -> payment em vez de
  esconder tudo em um façade único.

- Testes que protegem a feature:
  `test/integration/openfinance_partner_flow_test.rb`,
  `test/models/consent_test.rb`,
  `test/models/payment_initiation_test.rb`.

### Webhook delivery com replay e assinatura

- Problema que resolve:
  parceiro precisa validar integração sem ambiente bancário real, inclusive em
  cenários de falha.

- Commits principais:
  `b71ce30`, `c9bee45`, `18ee896`, `6be8b9f`.

- Arquivos principais:
  `app/services/sandbox/webhook_http_client.rb`,
  `app/services/sandbox/webhook_endpoint_policy.rb`,
  `app/models/webhook_delivery.rb`,
  `app/controllers/ops/webhook_deliveries_controller.rb`.

- Prós:
  ensina integração séria com estado e replay.

- Contras:
  aumenta a quantidade de moving parts para um sandbox local.

### Console `/ops` como parte do produto

- Problema que resolve:
  alguém precisa inspecionar consents, payments, cenários e entregas.

- Commits principais:
  `9ab1940`, `6d61465`.

- Arquivos principais:
  `app/controllers/ops/*`,
  `test/system/ops_console_test.rb`.

- O que isso ensina:
  produto de integração bom não termina no endpoint público.

## 4. Decisão por decisão

- Sandbox determinístico em vez de mock trivial:
  escolhido para ensinar fluxos e falhas reproduzíveis.

- Monólito híbrido em vez de API pura:
  escolhido porque operação humana também faz parte do aprendizado.

- Webhook real com replay:
  escolhido para aproximar o sandbox da vida de integração de parceiro.

- Egress policy e credential rotation:
  escolhidos porque segurança de integração não pode ser nota de rodapé.

## 5. Prós e contras das escolhas principais

- Determinismo por cenário:
  pró: QA e estudo reproduzíveis.
  contra: menos fidelidade a aleatoriedade do mundo real.

- Webhook real:
  pró: ensina mais.
  contra: exige mais harness de teste.

- Console integrado:
  pró: facilita leitura de ponta a ponta.
  contra: expande superfície da aplicação.

## 6. Erros, correções e endurecimentos

- O histórico mostra que webhook contract, replay signature e egress safe path
  não ficaram “bons o bastante” na primeira versão; voltaram como correções
  explícitas.
- Credential rotation só apareceu na fase final, o que combina com um padrão
  realista: primeiro a autenticação existe, depois o lifecycle fica maduro.

## 7. Como os testes foram usados

- Primeiro para cobrir o fluxo geral do sandbox.
- Depois para validar isolamento, contracts públicos, entrega HTTP real e
  comportamento operacional do console.

## 8. Quais testes protegem quais decisões

- Partner flow:
  `test/integration/openfinance_partner_flow_test.rb`.

- Auth/isolation:
  `test/integration/authorization_and_isolation_test.rb`,
  `test/integration/developer_app_credentials_test.rb`.

- Contratos:
  `test/integration/openapi_response_contract_test.rb`,
  `test/repository_spec_compliance_test.rb`.

- Webhook e replay:
  `test/models/webhook_delivery_test.rb`,
  `test/integration/failure_scenarios_test.rb`,
  `test/system/ops_console_test.rb`.

## 9. Timeline dos commits atômicos

| Commit | Pergunta que o commit responde | Mudança principal | Prova |
| --- | --- | --- | --- |
| `4fec496` | O que o repo quer ensinar? | baseline documental | docs |
| `1e4ce39` | Como preparar a base Rails? | shell híbrido | scaffold |
| `0857514` | Quais agregados existem? | modelagem do sandbox | models/services |
| `27ce9fb` | Como autenticar e autorizar? | security services | tests |
| `01e626d` | Como expor a API parceira? | endpoints versionados | integration |
| `9ab1940` | Como operar o sandbox? | console ops | system path |
| `6d61465` | Como observar e recuperar? | alerts + backup tooling | ops/docs |
| `37223dc` | O fluxo end-to-end já é provado? | cobertura Minitest | tests |
| `be22296` | Como medir localmente? | benchmark suite | bench docs |
| `cdcdf52` | Como falar de readiness? | arquitetura + segurança + produção | docs |
| `d4b2a6e` | Qual é a barra de qualidade? | workflow de CI | actions |
| `77353ba` | Como aprofundar consent/eventos? | docs de Open Finance | docs |
| `b71ce30` | O webhook fala o mesmo idioma da API v1? | alinhamento de eventos | event docs/tests |
| `7b52add` | O sandbox está pronto para produção local? | readiness hardening | docs/tests |
| `d53fcf9` | Como impedir egress perigoso? | webhook egress guard | security |
| `c9bee45` | O HTTP delivery é real ou só mock? | cobertura de entrega real | integration |
| `fb04622` | O OpenAPI ainda bate com o runtime? | schema validation | contract tests |
| `18ee896` | Replay ainda preserva assinatura? | replay signature fix | tests |
| `6be8b9f` | O contrato de evento está estável? | event contract tests | tests |
| `567dab9` | Como maturar credenciais do parceiro? | credential rotation | auth flow |

## 9A. Perguntas de recuperação

- Em que ponto uma app credential deixa de bastar e o bearer token passa a ser
  obrigatório?
- Qual arquivo você abriria primeiro para investigar replay quebrado?
- O que o console `/ops` prova que a API pública sozinha não prova?

## 10. Comandos de terminal que um specialist usaria aqui

```bash
git log --oneline --reverse
git show --stat b71ce30
DATABASE_ADAPTER=sqlite3 ruby bin/rails test test/integration/openfinance_partner_flow_test.rb
DATABASE_ADAPTER=sqlite3 ruby bin/rails test test/integration/openapi_response_contract_test.rb
DATABASE_ADAPTER=sqlite3 ruby bin/rails test:system
DATABASE_ADAPTER=sqlite3 ruby bin/rubocop
DATABASE_ADAPTER=sqlite3 ruby bin/brakeman --quiet --no-pager
DATABASE_ADAPTER=sqlite3 ruby bin/bundler-audit
```

## 11. Como adicionar a próxima feature sem quebrar a aula

Se a próxima feature for um novo recurso Open Finance:

1. fixe o papel do aggregate;
2. decida se ele depende de app credential, consent ou bearer token;
3. torne o contrato público explícito;
4. adicione falha e replay se houver efeito assíncrono;
5. exponha a inspeção no `/ops` só depois do core ficar claro.

## 12. Limites de produção deixados de propósito

- não implementa certificação Open Finance real;
- não pretende substituir diretório, mTLS ou identity provider reais;
- não prova operação multi-tenant de banco real;
- mantém o foco em learnability, previsibilidade e boundary clarity.
