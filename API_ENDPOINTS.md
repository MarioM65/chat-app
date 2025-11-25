# Documentação da API

Este documento detalha todos os endpoints da API REST e da API WebSocket.

**URL Base**: `http://localhost:3000` (ou o seu endereço de produção)

---

## API REST

### Respostas Padronizadas da API

Todas as respostas da API REST seguem um formato padronizado para consistência e facilidade de consumo.

#### Resposta de Sucesso
As respostas bem-sucedidas terão o seguinte formato:
```json
{
  "success": true,
  "statusCode": 200, // Ou outro código de sucesso HTTP (201, 204, etc.)
  "message": "Success", // Mensagem genérica de sucesso, pode ser mais específica
  "data": {
    // Os dados reais retornados pelo endpoint
  }
}
```

#### Resposta de Erro
As respostas de erro terão o seguinte formato:
```json
{
  "success": false,
  "statusCode": 400, // Ou outro código de erro HTTP (401, 403, 404, 500, etc.)
  "timestamp": "2025-11-17T10:00:00.000Z",
  "path": "/api/v1/users",
  "message": "Bad Request", // Mensagem de erro principal
  "error": {
    // Detalhes adicionais do erro, como erros de validação
    "statusCode": 400,
    "message": [
      "email must be an email",
      "password should not be empty"
    ],
    "error": "Bad Request"
  }
}
```
**Validação de DTOs:**
A validação de entrada é aplicada globalmente usando `ValidationPipe`. Isso significa que todos os DTOs (`Data Transfer Objects`) são automaticamente validados com base nas regras definidas pelos decoradores `class-validator`. Erros de validação resultarão em uma resposta de erro com `statusCode: 400 Bad Request` e detalhes dos campos inválidos no campo `error.message`.

### Auth
- `POST /auth/login`
  - **Descrição**: Autentica um utilizador.
  - **Request Body**:
    ```json
    {
      "email": "user@example.com",
      "senha": "password123"
    }
    ```
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "user": {
          // Objeto do utilizador autenticado (sem a senha)
        }
      }
    }
    ```
  - **Error Response (401)**:
    ```json
    {
      "success": false,
      "statusCode": 401,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/auth/login",
      "message": "Invalid credentials",
      "error": "Unauthorized"
    }
    ```

- `POST /auth/register`
  - **Descrição**: Regista um novo utilizador.
  - **Request Body**:
    ```json
    {
      "nome_usuario": "Novo Utilizador",
      "email": "newuser@example.com",
      "senha": "password123",
      "foto_perfil": "url_da_foto.jpg",
      "telefone": "123456789"
    }
    ```
  - **Success Response (201)**:
    ```json
    {
      "success": true,
      "statusCode": 201,
      "message": "Success",
      "data": {
        "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
        "user": {
          // Objeto do utilizador criado (sem a senha)
        }
      }
    }
    ```
  - **Error Response (409)**:
    ```json
    {
      "success": false,
      "statusCode": 409,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/auth/register",
      "message": "User with this email already exists",
      "error": "Conflict"
    }
    ```

### Users
- `GET /users`
  - **Descrição**: Retorna uma lista de todos os utilizadores.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": [
        // Array de objetos de utilizador
      ]
    }
    ```
- `GET /users/:id`
  - **Descrição**: Retorna um utilizador específico pelo seu ID.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto do utilizador
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/users/1",
      "message": "User not found",
      "error": "Not Found"
    }
    ```
- `POST /users`
  - **Descrição**: Cria um novo utilizador (similar a `/auth/register`, mas pode ser usado por admins). Aceita `multipart/form-data` para upload de `foto_perfil`.
  - **Success Response (201)**:
    ```json
    {
      "success": true,
      "statusCode": 201,
      "message": "Success",
      "data": {
        // Objeto do utilizador criado
      }
    }
    ```
  - **Error Response (409)**:
    ```json
    {
      "success": false,
      "statusCode": 409,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/users",
      "message": "User with this email already exists",
      "error": "Conflict"
    }
    ```
- `PUT /users/:id`
  - **Descrição**: Atualiza os dados de um utilizador. Aceita `multipart/form-data` para upload de `foto_perfil`.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto do utilizador atualizado
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/users/1",
      "message": "User not found",
      "error": "Not Found"
    }
    ```
  - **Error Response (409)**:
    ```json
    {
      "success": false,
      "statusCode": 409,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/users/1",
      "message": "User with this email already exists",
      "error": "Conflict"
    }
    ```
- `DELETE /users/:id`
  - **Descrição**: Realiza um "soft delete" de um utilizador (marca como deletado).
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto do utilizador deletado (soft delete)
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/users/1",
      "message": "User not found",
      "error": "Not Found"
    }
    ```
- `DELETE /users/purge/:id`
  - **Descrição**: Remove permanentemente um utilizador da base de dados.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto do utilizador removido permanentemente
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/users/purge/1",
      "message": "User not found",
      "error": "Not Found"
    }
    ```
- `GET /users/trashed/all`
  - **Descrição**: Lista todos os utilizadores que foram "soft-deleted".
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": [
        // Array de objetos de utilizador "soft-deleted"
      ]
    }
    ```
- `PUT /users/restore/:id`
  - **Descrição**: Restaura um utilizador que foi "soft-deleted".
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto do utilizador restaurado
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/users/restore/1",
      "message": "User not found",
      "error": "Not Found"
    }
    ```

### Conversas
- `GET /conversas`
  - **Descrição**: Retorna todas as conversas.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": [
        // Array de objetos de conversa
      ]
    }
    ```
- `GET /conversas/:id_conversa`
  - **Descrição**: Retorna uma conversa específica.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de conversa
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/conversas/1",
      "message": "Conversa not found",
      "error": "Not Found"
    }
    ```
- `POST /conversas`
  - **Descrição**: Cria uma nova conversa.
  - **Request Body**:
    ```json
    {
      "tipo_conversa": "grupo",
      "nome_conversa": "Grupo de Trabalho"
    }
    ```
  - **Success Response (201)**:
    ```json
    {
      "success": true,
      "statusCode": 201,
      "message": "Success",
      "data": {
        // Objeto de conversa criada
      }
    }
    ```
- `PUT /conversas/:id_conversa`
  - **Descrição**: Atualiza os dados de uma conversa.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de conversa atualizada
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/conversas/1",
      "message": "Conversa not found",
      "error": "Not Found"
    }
    ```
- `DELETE /conversas/:id_conversa`
  - **Descrição**: Deleta uma conversa.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de conversa deletada
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/conversas/1",
      "message": "Conversa not found",
      "error": "Not Found"
    }
    ```

### Participantes de Conversas
- `GET /participante_conversas`
  - **Descrição**: Lista todas as relações de participantes.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": [
        // Array de objetos de participante de conversa
      ]
    }
    ```
- `GET /participante_conversas/:id_participante_conversa`
  - **Descrição**: Obtém uma relação específica.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de participante de conversa
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/participante_conversas/1",
      "message": "ParticipanteConversa not found",
      "error": "Not Found"
    }
    ```
- `GET /participante_conversas/conversa/:id_conversa`
  - **Descrição**: Lista todos os participantes de uma conversa específica.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": [
        // Array de objetos de participante de conversa
      ]
    }
    ```
- `GET /participante_conversas/usuario/:id_usuario`
  - **Descrição**: Lista todas as conversas em que um utilizador é participante.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": [
        // Array de objetos de participante de conversa
      ]
    }
    ```
- `POST /participante_conversas`
  - **Descrição**: Adiciona um utilizador a uma conversa. **Requer permissão de `ADMIN` ou `CRIADOR`**.
  - **Request Body**:
    ```json
    {
      "id_conversa": 1,
      "id_usuario": 2,
      "tipo_participante": "MEMBRO"
    }
    ```
  - **Success Response (201)**:
    ```json
    {
      "success": true,
      "statusCode": 201,
      "message": "Success",
      "data": {
        // Objeto de participante de conversa criado
      }
    }
    ```
- `PUT /participante_conversas/:id_participante_conversa`
  - **Descrição**: Atualiza o status de um participante (ex: de `MEMBRO` para `ADMIN`). **Requer permissão de `ADMIN` ou `CRIADOR`**.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de participante de conversa atualizado
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/participante_conversas/1",
      "message": "ParticipanteConversa not found",
      "error": "Not Found"
    }
    ```
- `DELETE /participante_conversas/:id_participante_conversa`
  - **Descrição**: Remove um utilizador de uma conversa. **Requer permissão de `ADMIN` ou `CRIADOR`**.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de participante de conversa deletado
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/participante_conversas/1",
      "message": "ParticipanteConversa not found",
      "error": "Not Found"
    }
    ```

### Mensagens
- `GET /mensagens`
  - **Descrição**: Retorna todas as mensagens com seus anexos.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": [
        // Array de objetos de mensagem com anexos
      ]
    }
    ```
- `GET /mensagens/:id`
  - **Descrição**: Retorna uma mensagem específica com seus anexos.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        "id": 1,
        "conteudo": "Exemplo de mensagem",
        // ... outros campos da mensagem
        "anexos": [
          {
            "id": 1,
            "nome_arquivo": "documento.pdf",
            "caminho_arquivo": "uploads/mensagens_anexos/...",
            "tipo": "application/pdf",
            "tamanho": 1024
          }
        ]
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/mensagens/1",
      "message": "Mensagem not found",
      "error": "Not Found"
    }
    ```
- `POST /mensagens`
  - **Descrição**: Cria uma nova mensagem com múltiplos anexos. Aceita `multipart/form-data`.
  - **Request Body (form-data)**:
    - `id_remetente`: 1
    - `id_conversa`: 2
    - `conteudo`: "Mensagem de texto com anexos."
    - `tipo`: "texto"
    - `anexos`: (array de ficheiros)
  - **Success Response (201)**:
    ```json
    {
      "success": true,
      "statusCode": 201,
      "message": "Success",
      "data": {
        "id": 2,
        "conteudo": "Mensagem de texto com anexos.",
        // ... outros campos
        "anexos": [
          // Array de objetos de anexo
        ]
      }
    }
    ```
- `PUT /mensagens/:id`
  - **Descrição**: Atualiza uma mensagem.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de mensagem atualizada
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/mensagens/1",
      "message": "Mensagem not found",
      "error": "Not Found"
    }
    ```
- `DELETE /mensagens/:id`
  - **Descrição**: Deleta uma mensagem. **Apenas o remetente ou um `ADMIN`/`CRIADOR` da conversa pode executar esta ação.**
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de mensagem deletada
      }
    }
    ```
  - **Error Response (403)**:
    ```json
    {
      "success": false,
      "statusCode": 403,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/mensagens/1",
      "message": "You do not have permission to delete this message",
      "error": "Forbidden"
    }
    ```

### Anexos
- `GET /anexos`
  - **Descrição**: Lista todos os anexos.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": [
        // Array de objetos de anexo
      ]
    }
    ```
- `GET /anexos/:id`
  - **Descrição**: Obtém um anexo específico.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de anexo
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/anexos/1",
      "message": "Anexo not found",
      "error": "Not Found"
    }
    ```
- `POST /anexos`
  - **Descrição**: Cria um novo anexo. Requer `multipart/form-data` com o ficheiro no campo `arquivo`.
  - **Success Response (201)**:
    ```json
    {
      "success": true,
      "statusCode": 201,
      "message": "Success",
      "data": {
        // Objeto de anexo criado
      }
    }
    ```
- `PUT /anexos/:id`
  - **Descrição**: Atualiza um anexo.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de anexo atualizado
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/anexos/1",
      "message": "Anexo not found",
      "error": "Not Found"
    }
    ```
- `DELETE /anexos/:id`
  - **Descrição**: Deleta um anexo.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de anexo deletado
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/anexos/1",
      "message": "Anexo not found",
      "error": "Not Found"
    }
    ```

### Leitura de Mensagens
- `GET /leitura_mensagens`
  - **Descrição**: Lista todos os registos de leitura.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": [
        // Array de objetos de leitura de mensagem
      ]
    }
    ```
- `POST /leitura_mensagens`
  - **Descrição**: Marca uma mensagem como lida por um utilizador.
  - **Request Body**:
    ```json
    {
      "id_mensagem": 101,
      "id_usuario": 2,
      "data_hora_leitura": "2025-11-16T12:00:00.000Z"
    }
    ```
  - **Success Response (201)**:
    ```json
    {
      "success": true,
      "statusCode": 201,
      "message": "Success",
      "data": {
        // Objeto de leitura de mensagem criada
      }
    }
    ```
- `GET /leitura_mensagens/:id`
  - **Descrição**: Retorna um registo de leitura específico.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de leitura de mensagem
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/leitura_mensagens/1",
      "message": "LeituraMensagem not found",
      "error": "Not Found"
    }
    ```
- `PUT /leitura_mensagens/:id`
  - **Descrição**: Atualiza um registo de leitura.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de leitura de mensagem atualizada
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/leitura_mensagens/1",
      "message": "LeituraMensagem not found",
      "error": "Not Found"
    }
    ```
- `DELETE /leitura_mensagens/:id`
  - **Descrição**: Deleta um registo de leitura.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de leitura de mensagem deletada
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/leitura_mensagens/1",
      "message": "LeituraMensagem not found",
      "error": "Not Found"
    }
    ```

### Notificações
- `GET /notificacoes`
  - **Descrição**: Lista todas as notificações.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": [
        // Array de objetos de notificação
      ]
    }
    ```
- `POST /notificacoes`
  - **Descrição**: Cria uma notificação.
  - **Success Response (201)**:
    ```json
    {
      "success": true,
      "statusCode": 201,
      "message": "Success",
      "data": {
        // Objeto de notificação criada
      }
    }
    ```
- `GET /notificacoes/:id`
  - **Descrição**: Retorna uma notificação específica.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de notificação
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/notificacoes/1",
      "message": "Notificacao not found",
      "error": "Not Found"
    }
    ```
- `PUT /notificacoes/:id`
  - **Descrição**: Atualiza uma notificação.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de notificação atualizada
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/notificacoes/1",
      "message": "Notificacao not found",
      "error": "Not Found"
    }
    ```
- `DELETE /notificacoes/:id`
  - **Descrição**: Deleta uma notificação.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de notificação deletada
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/notificacoes/1",
      "message": "Notificacao not found",
      "error": "Not Found"
    }
    ```

### Utilizadores Bloqueados
- `GET /users-bloqueados`
  - **Descrição**: Lista todas as relações de bloqueio.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": [
        // Array de objetos de utilizador bloqueado
      ]
    }
    ```
- `GET /users-bloqueados/:id`
  - **Descrição**: Obtém uma relação de bloqueio específica.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de utilizador bloqueado
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/users-bloqueados/1",
      "message": "UserBloqueado not found",
      "error": "Not Found"
    }
    ```
- `GET /users-bloqueados/user/:id_usuario`
  - **Descrição**: Lista todos os utilizadores que um determinado `id_usuario` bloqueou.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": [
        // Array de objetos de utilizador bloqueado
      ]
    }
    ```
- `POST /users-bloqueados`
  - **Descrição**: Bloqueia um utilizador.
  - **Request Body**:
    ```json
    {
      "id_usuario": 1,
      "id_usuario_bloqueado": 3
    }
    ```
  - **Success Response (201)**:
    ```json
    {
      "success": true,
      "statusCode": 201,
      "message": "Success",
      "data": {
        // Objeto de utilizador bloqueado criado
      }
    }
    ```
- `PUT /users-bloqueados/:id`
  - **Descrição**: Atualiza uma relação de bloqueio.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de utilizador bloqueado atualizado
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/users-bloqueados/1",
      "message": "UserBloqueado not found",
      "error": "Not Found"
    }
    ```
- `DELETE /users-bloqueados/:id`
  - **Descrição**: Deleta uma relação de bloqueio.
  - **Success Response (200)**:
    ```json
    {
      "success": true,
      "statusCode": 200,
      "message": "Success",
      "data": {
        // Objeto de utilizador bloqueado deletado
      }
    }
    ```
  - **Error Response (404)**:
    ```json
    {
      "success": false,
      "statusCode": 404,
      "timestamp": "2025-11-17T10:00:00.000Z",
      "path": "/users-bloqueados/1",
      "message": "UserBloqueado not found",
      "error": "Not Found"
    }
    ```

---

## API WebSocket

Esta API permite a comunicação em tempo real para funcionalidades de chat.

### Conexão

Para se conectar ao servidor WebSocket a partir do Flutter, utilize a biblioteca `socket_io_client`.

**URL de Conexão**: `http://localhost:3000` (a biblioteca trata da conversão para o protocolo WebSocket)

### Eventos (Cliente para Servidor)

Estes são os eventos que o seu cliente Flutter deve **emitir** para o servidor.

#### `joinRoom`
- **Descrição**: Entra numa sala de chat específica para receber mensagens de uma conversa. Deve ser emitido sempre que o utilizador abre uma tela de conversa.
- **Payload**: `String` - O ID da conversa que o utilizador está a visualizar.
  ```dart
  // Exemplo de payload
  String conversationId = '123';
  socket.emit('joinRoom', conversationId);
  ```

#### `leaveRoom`
- **Descrição**: Sai de uma sala de chat. Deve ser emitido quando o utilizador fecha ou sai da tela de uma conversa para parar de receber mensagens.
- **Payload**: `String` - O ID da conversa da qual o utilizador está a sair.
  ```dart
  // Exemplo de payload
  String conversationId = '123';
  socket.emit('leaveRoom', conversationId);
  ```

#### `chatMessage`
- **Descrição**: Envia uma nova mensagem para uma conversa. O servidor irá persistir a mensagem na base de dados e transmiti-la para todos os outros membros da sala.
- **Payload**: `Map<String, dynamic>` - Corresponde à estrutura `CreateMensagem`.
  ```json
  {
    "id_remetente": 1,
    "id_conversa": 123,
    "conteudo": "Olá do Flutter!",
    "tipo": "texto"
  }
  ```

### Eventos (Servidor para Cliente)

Estes são os eventos que o seu cliente Flutter deve **ouvir**.

#### `chatMessage`
- **Descrição**: Recebe uma nova mensagem de uma conversa na qual o utilizador entrou (via `joinRoom`).
- **Payload**: `Map<String, dynamic>` - A mensagem completa, já guardada na base de dados. O conteúdo da mensagem é desencriptado pelo servidor antes de ser enviado.
  ```json
  {
    "id": 102,
    "id_remetente": 2,
    "id_conversa": 123,
    "conteudo": "Olá, recebi a sua mensagem!",
    "tipo": "texto",
    "lida": false,
    "respondendo_a": null,
    "criado_em": "2025-11-16T10:10:00.000Z",
    "deletado_em": null,
    "isViewUnic": null,
    "iv": "<vetor de inicialização>",
    "remetente": {
      "id": 2,
      "nome_usuario": "Outro Utilizador"
    }
  }
  ```

#### `error`
- **Descrição**: O servidor emite este evento se ocorrer um erro ao processar uma mensagem.
- **Payload**: `String` - Uma mensagem de erro.
  ```dart
  // Exemplo de como ouvir
  socket.on('error', (data) => print('Erro do servidor: $data'));
  ```

### Exemplo de Cliente em Flutter/Dart

Adicione a dependência ao seu `pubspec.yaml`:
```yaml
dependencies:
  socket_io_client: ^2.0.3 # Verifique a versão mais recente
```

Crie um serviço para gerir a conexão WebSocket:
```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect() {
    // NOTA: Use o IP da sua máquina se estiver a testar num emulador Android.
    // Não use 'localhost' ou '127.0.0.1'.
    // Para iOS, 'localhost' funciona se o servidor estiver na mesma máquina.
    socket = IO.io('http://SEU_IP_LOCAL:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('Conectado ao servidor WebSocket');
    });

    socket.onDisconnect((_) => print('Desconectado'));
  }

  // Ouvir por novas mensagens
  void onChatMessage(Function(Map<String, dynamic>) handler) {
    socket.on('chatMessage', (data) => handler(data));
  }

  // Entrar numa sala de conversa
  void joinConversation(String conversationId) {
    socket.emit('joinRoom', conversationId);
  }

  // Sair de uma sala de conversa
  void leaveConversation(String conversationId) {
    socket.emit('leaveRoom', conversationId);
  }

  // Enviar uma mensagem
  void sendMessage({
    required int senderId,
    required int conversationId,
    required String content,
  }) {
    final message = {
      'id_remetente': senderId,
      'id_conversa': conversationId,
      'conteudo': content,
      'tipo': 'texto',
    };
    socket.emit('chatMessage', message);
  }

  void disconnect() {
    socket.disconnect();
  }
}
```
