# GameVault

Catálogo de jogos cloud-native deployado na AWS com arquitetura serverless + containers. Desenvolvido em Go e Python para a disciplina de Serviços em Nuvem.

CRUD completo sobre uma entidade `Game`, com função Lambda dedicada para geração de relatório estatístico do catálogo.

---

## Arquitetura

```text
Usuário
   │
   ▼
┌─────────────────────────────────────────────┐
│            Amazon API Gateway               │
│            (ponto único de entrada)         │
└──┬──────────────┬──────────────┬────────────┘
   │              │              │
   │ /games       │ /report      │ /*
   ▼              ▼              ▼
┌──────────┐  ┌──────────┐  ┌───────────┐
│ Backend  │  │  Lambda  │  │ Front-end │
│ Go+Gin   │  │  Python  │  │ Go+Gin    │
│ (ECS)    │  │          │  │ (ECS)     │
└────┬─────┘  └────┬─────┘  └───────────┘
     │             │
     │             │ HTTP GET /games
     │             │ (via API Gateway)
     │             ▼
     │       ┌──────────┐
     │       │ Calcula  │
     │       │  stats   │
     │       └──────────┘
     ▼
┌──────────────┐
│ Amazon RDS   │
│ PostgreSQL   │
│ (subnet      │
│  privada)    │
└──────────────┘
```

### Regras da arquitetura

1. **Front-end** *não* fala diretamente com o back-end — todas as requisições passam pelo API Gateway.
2. **Lambda** *não* acessa o RDS — consome a API HTTP via API Gateway e calcula estatísticas em memória.
3. **RDS** fica em subnet privada, sem porta exposta à Internet. Apenas o back-end se conecta.
4. **JS no browser** chama o API Gateway diretamente (CORS configurado).

---

## Tecnologias

| Camada | Tecnologia |
|--------|------------|
| Back-end | Go 1.25, Gin, GORM |
| Front-end | Go 1.24, Gin, HTML templates, JS vanilla |
| Banco de dados | PostgreSQL 17 (Amazon RDS) |
| Função serverless | Python 3.12 (AWS Lambda) |
| Containers | Docker (multi-stage build) |
| Orquestração local | Docker Compose |
| Gateway | Amazon API Gateway (HTTP API) |
| Compute | Amazon ECS Fargate |

---

## Estrutura do projeto

```text
aws-gamevault/
├── backend/                    # API REST do CRUD
│   ├── controllers/
│   │   ├── game_controller.go
│   │   └── report_controller.go    # versão dev local da Lambda
│   ├── database/
│   │   └── connection.go
│   ├── models/
│   │   └── game.go
│   ├── main.go
│   ├── Dockerfile
│   └── go.mod
│
├── web/                        # Front-end servindo HTML+JS+CSS
│   ├── controllers/
│   │   └── page_controller.go
│   ├── static/
│   │   ├── css/style.css       # tema Dark Vault
│   │   └── js/app.js           # CRUD via fetch
│   ├── templates/
│   │   └── index.html
│   ├── main.go
│   ├── Dockerfile
│   └── go.mod
│
├── lambda/
│   └── report.py               # função AWS Lambda
│
├── sql/
│   └── init.sql                # CREATE TABLE + 10 jogos seed
│
├── docker-compose.yml          # backend + web + postgres para dev local
├── README.md
└── LICENSE
```

---

## Como rodar localmente

### Pré-requisitos

- Docker Desktop

### Passo a passo

Na raiz do projeto:

```bash
docker compose up --build
```

Aguarde as três mensagens de boot:

- `gamevault-db` ... `healthy`
- `gamevault-backend` ... `conexão com PostgreSQL estabelecida`
- `gamevault-web` ... `Listening and serving HTTP on :3000`

Acesse:

- **Front-end:** [http://localhost:3000](http://localhost:3000)
- **API direta:** [http://localhost:8080/games](http://localhost:8080/games)

Para parar tudo e limpar volumes (recomeçar do zero com seed):

```bash
docker compose down -v
```

### Variáveis de ambiente (back-end)

| Variável | Descrição | Default |
|----------|-----------|---------|
| `DB_HOST` | Host do PostgreSQL | — |
| `DB_PORT` | Porta do PostgreSQL | — |
| `DB_USER` | Usuário | — |
| `DB_PASSWORD` | Senha | — |
| `DB_NAME` | Nome do banco | — |
| `GIN_MODE` | `release` em produção | `debug` |

### Variáveis de ambiente (front-end)

| Variável | Descrição | Default |
|----------|-----------|---------|
| `WEB_PORT` | Porta de escuta | `3000` |
| `API_GATEWAY_URL` | URL base do API Gateway | `http://localhost:8080` |

---

## Endpoints da API

| Método | Rota | Descrição | Status codes |
|--------|------|-----------|--------------|
| GET | `/games` | Lista todos os jogos | 200 |
| GET | `/games/:id` | Busca jogo por ID | 200, 404 |
| POST | `/games` | Cria um novo jogo | 201, 400 |
| PUT | `/games/:id` | Atualiza jogo existente | 200, 400, 404 |
| DELETE | `/games/:id` | Remove jogo | 200, 404 |
| GET | `/report` | Estatísticas do catálogo (Lambda) | 200, 502 |

### Modelo `Game`

```json
{
  "id": 1,
  "name": "The Witcher 3: Wild Hunt",
  "genre": "RPG",
  "platform": "PC",
  "rating": 9.8,
  "release_year": 2015,
  "created_at": "2026-05-07T12:17:02.781694Z",
  "updated_at": "2026-05-07T12:17:02.781694Z"
}
```

### Validações

- `name`, `genre`, `platform`: obrigatórios
- `rating`: obrigatório, entre 0 e 10
- `release_year`: obrigatório

---

## Rota `/report` (Lambda)

A função Lambda em Python recebe um evento do API Gateway, faz `GET /games` (também via API Gateway, sem acessar o RDS) e devolve estatísticas calculadas em memória.

### Resposta

```json
{
  "total_games": 10,
  "average_rating": 9.06,
  "games_by_genre": {
    "RPG": 4,
    "FPS": 2,
    "Action": 1,
    "Metroidvania": 1,
    "Plataforma": 1,
    "Simulation": 1
  },
  "games_by_platform": {
    "PC": 7,
    "PlayStation": 2,
    "Xbox": 1
  },
  "highest_rated": {
    "name": "The Witcher 3: Wild Hunt",
    "rating": 9.8
  },
  "lowest_rated": {
    "name": "Cyberpunk 2077",
    "rating": 7.5
  }
}
```

### Variável de ambiente da Lambda

| Variável | Descrição |
|----------|-----------|
| `API_URL` | URL base do API Gateway (ex.: `https://abc123.execute-api.us-east-1.amazonaws.com/prod`) |

> **Em dev local** existe uma rota `/report` no backend Go que simula a Lambda, calculando direto do banco. Em produção, o API Gateway roteia `/report` direto para a Lambda — o backend não é tocado.

---

## Deploy na AWS

A infraestrutura é provisionada manualmente no Console AWS, na seguinte ordem:

1. **VPC** com 2 subnets públicas e 2 privadas em AZs diferentes.
2. **RDS PostgreSQL 17** na subnet privada, sem acesso público. Security Group permite entrada apenas do SG do ECS.
3. **ECR** com 2 repositórios: `gamevault-backend` e `gamevault-web`. Push das imagens com `docker push`.
4. **ECS Fargate** com 2 services:
   - `backend`: usa a imagem `gamevault-backend`, env vars apontando para o RDS, porta 8080.
   - `web`: usa a imagem `gamevault-web`, env var `API_GATEWAY_URL` com a URL do API Gateway, porta 3000.
5. **Lambda Python 3.12**: cria a função, faz upload do `lambda/report.py`, define a variável `API_URL`.
6. **API Gateway (HTTP API)** com 4 integrações:
   - `ANY /games` → ECS backend
   - `ANY /games/{id}` → ECS backend
   - `GET /report` → Lambda
   - `ANY /{proxy+}` → ECS web
7. **CORS** configurado no API Gateway para permitir o domínio do front-end.

### Migração do schema

O `sql/init.sql` cria a tabela `games` e popula com 10 jogos seed. Para rodar no RDS:

```bash
psql -h <RDS_ENDPOINT> -U <USER> -d <DBNAME> -f sql/init.sql
```

Alternativamente, o GORM `AutoMigrate` cria a tabela automaticamente no primeiro boot do back-end.

---

## Autor

Pedro Henrique Leite — disciplina de Serviços em Nuvem.
