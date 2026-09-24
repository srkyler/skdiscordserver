<div align="center">

# SKDiscordServ

**Ponte leve entre o seu servidor Minecraft e o Discord — embeds bonitos com a cabeça da skin de cada jogador.**

![Java](https://img.shields.io/badge/Java-21-orange?logo=openjdk&logoColor=white)
![Paper](https://img.shields.io/badge/Paper-1.21%2B-blue)
![Folia](https://img.shields.io/badge/Folia-suportado-brightgreen)
![Tamanho](https://img.shields.io/badge/jar-~40%20KB-lightgrey)
![Dependências](https://img.shields.io/badge/depend%C3%AAncias-zero-success)

</div>

---

## O que é

O **SKDiscordServ** é uma alternativa enxuta ao DiscordSRV para quem só quer **mostrar no Discord o que acontece no servidor**: entradas, saídas, chat, mortes, conquistas e o status do servidor, tudo em embeds organizados com a cabeça da skin do jogador ao lado.

Em vez de um bot, ele usa um **webhook do Discord**. Não precisa criar aplicação no Developer Portal, não precisa de token de bot e não abre nenhuma porta. É colar a URL do webhook e ligar.

> **Ponte de mão única (jogo → Discord).** Nada que é digitado no Discord chega ao servidor. Isso é proposital: nenhum comando ou mensagem externa consegue executar nada no jogo.

## Recursos

- 🟢 **Entrada, primeira entrada e saída** — com contador `online/máximo` no rodapé
- 💬 **Chat espelhado** — uma mensagem por embed, com a cabeça do autor
- ⚔️ **Mortes traduzidas para português**, separadas em **PvP** e **PvE**, com cores próprias
  - Mostra quem matou e com qual arma (`foi morto por Fulano usando espada de netherita`)
  - Entende kills de crystal, TNT, flecha, tridente, maça e itens com nome customizado
  - Mais de 30 tipos de morte e 40 mobs já traduzidos, tudo editável no `config.yml`
- 🏆 **Conquistas** (advancements) — ignora receitas e conquistas ocultas para não floodar o canal
- 🔌 **Servidor ligado / desligado** — o aviso de desligamento é enviado antes do processo fechar
- 🎨 **Tudo configurável**: textos, cores (hex), rodapés, nome e avatar do webhook, fonte da cabeça da skin
- 🏴‍☠️ **Funciona em servidor offline (pirata)** — basta trocar a URL da cabeça para usar `%name%`

## Desempenho

- **Nada de HTTP na thread do jogo.** Os eventos só entram numa fila; o envio acontece em uma tarefa assíncrona.
- **Até 10 embeds por requisição.** Dez jogadores entrando juntos custam 1 chamada à API, não 10.
- **Respeita o rate limit do Discord** (lê o `retry_after`, pausa e reenvia na ordem original).
- **Fila com teto** (`queue-limit`) — se o Discord cair durante um pico, a memória do servidor não vai junto.
- **Compatível com Folia** — usa os schedulers regionais/assíncronos e um snapshot imutável da config, seguro entre threads.
- **Sem bibliotecas embutidas** — usa o `HttpClient` do próprio JDK e monta o JSON à mão. O jar final tem ~40 KB.

## Segurança

Uma ponte com o Discord recebe texto de qualquer jogador, então o plugin foi feito pensando nisso:

| Proteção | O que evita |
|---|---|
| `allowed_mentions: []` em todo envio | Ninguém consegue pingar `@everyone`, cargos ou usuários pelo chat |
| Neutralização de menções e tokens `<@…>` | Texto que *parece* menção ou emoji customizado |
| Escape de markdown (inclusive `[ ]`) | Links mascarados de phishing do tipo `[clique aqui](site)` |
| Remoção de caracteres invisíveis e de direção (U+202E etc.) | Nicks falsificados e quebra de layout do embed |
| Bloqueio de mensagens que começam com `/` | Vazamento de `/login senha` por plugins de chat mal configurados |
| Mensagem cancelada (mute/filtro) não é enviada | O que não apareceu no jogo não aparece no Discord |
| Cooldown por jogador em entrada/saída e chat | Flood de quem fica entrando e saindo |
| Validação da URL do webhook e redirects desativados | O token do webhook nunca é enviado para outro host nem aparece no log |

## Requisitos

- Servidor **Paper** ou **Folia** 1.21+
- **Java 21**

## Instalação

1. Baixe o `SKDiscordServ.jar` na aba [Releases](../../releases) e coloque na pasta `plugins/`.
2. Inicie o servidor uma vez para gerar o `plugins/SKDiscordServ/config.yml`.
3. No Discord: **Editar Canal → Integrações → Webhooks → Novo Webhook → Copiar URL**.
4. No `config.yml`, cole a URL em `discord.webhook-url` e coloque `discord.enabled: true`.
5. Rode `/skdiscord reload` e depois `/skdiscord teste` para conferir.

> ⚠️ A URL do webhook é uma credencial: quem tiver ela posta no seu canal. **Não publique o seu `config.yml` preenchido.**

## Comandos e permissões

| Comando | Descrição |
|---|---|
| `/skdiscord reload` | Recarrega o `config.yml` sem reiniciar |
| `/skdiscord status` | Mostra se o envio está ativo, o tamanho da fila, mensagens descartadas e pausas por rate limit |
| `/skdiscord teste` | Envia um embed de teste para o canal |

Aliases: `/skdiscordserv`, `/discordserv`

| Permissão | Padrão | Descrição |
|---|---|---|
| `skdiscordserv.admin` | OP | Usar os comandos acima |
| `skdiscordserv.chat` | todos | Ter o chat espelhado (só vale com `chat-requires-permission: true`) |

## Configuração (resumo)

```yaml
discord:
  enabled: true
  webhook-url: 'https://discord.com/api/webhooks/...'
  name: 'MeuServidor'
  avatar-url: ''
  head-url: 'https://mc-heads.net/avatar/%uuid%/64'   # offline mode: .../avatar/%name%/64

performance:
  flush-interval-millis: 1500   # de quanto em quanto tempo a fila é enviada
  queue-limit: 500

anti-exploit:
  connection-cooldown-millis: 10000
  chat-cooldown-millis: 500
  escape-markdown: true
  chat-max-length: 500
  block-commands: true

events:
  join:
    enabled: true
    color: '#57F287'
    text: '%player% entrou no servidor'
    footer: '%online%/%max% jogadores online'
  # first-join, quit, death-pvp, death-pve, advancement, chat,
  # server-online, server-offline seguem o mesmo formato
```

**Placeholders:** `%player%` `%online%` `%max%` `%message%` `%advancement%`
**Mortes:** `%player%` (vítima), `%killer%` (quem matou), `%weapon%` (arma usada)

As seções `death-messages`, `death-weapons` e `death-mobs` usam os IDs do próprio Minecraft como chave, então dá para traduzir ou adicionar novos casos aos poucos — o que não estiver na lista cai na frase `padrao`.

<details>
<summary><b>Mortes e o gamerule <code>showDeathMessages</code></b></summary>

Por padrão, se o gamerule `showDeathMessages` estiver desligado no mundo, as mortes também não vão para o Discord. Com `events.death-ignore-gamerule: true`, elas são enviadas mesmo assim.

Mortes escondidas **por outro plugin** (arena, evento) continuam sendo respeitadas mesmo com essa opção ligada, para o canal não virar log de arena.

</details>

## SKDiscordServ x DiscordSRV

| | SKDiscordServ | DiscordSRV |
|---|---|---|
| Conexão | Webhook | Bot |
| Direção | Jogo → Discord | Bidirecional |
| Configuração | Colar uma URL | Criar bot, token, intents |
| Tamanho | ~40 KB, sem dependências | Vários MB |
| Folia | Suportado | Depende da versão |
| Vinculação de contas, sincronização de cargos, console no Discord | ❌ | ✅ |

Se você precisa de chat do Discord aparecendo no jogo, vínculo de contas ou console remoto, o DiscordSRV continua sendo a escolha certa. Se só quer um feed bonito, rápido e seguro do que acontece no servidor, o SKDiscordServ faz isso com muito menos peso.

## Compilando

O projeto não usa Maven nem Gradle — tem um script PowerShell:

```powershell
.\build.ps1
# ou, compilando e já copiando para o servidor:
.\build.ps1 -Deploy 'C:\caminho\do\servidor\plugins'
```

Os jars em `libs/` servem só para compilar (o servidor já fornece tudo em tempo de execução):

- `dev.folia:folia-api:26.1.2.build.8-stable`
- `net.kyori:adventure-api`, `adventure-key`, `adventure-text-serializer-legacy/plain/commons` `4.26.1`
- `net.kyori:examination-api:1.3.0`
- `net.md-5:bungeecord-chat:1.21-R0.2`
- `com.google.guava:guava:33.6.0-jre`
- `org.jetbrains:annotations:24.1.0`, `com.google.errorprone:error_prone_annotations:2.48.0`

O resultado sai em `build/SKDiscordServ.jar`.

## Estrutura

```
src/main/java/net/mylermc/discordserv/
├── SKDiscordServPlugin.java    # ciclo de vida, reload
├── DiscordConfig.java          # snapshot imutável da config
├── DeathTranslator.java        # frases de morte em PT-BR, PvP x PvE
├── DiscordServCommand.java     # /skdiscord
├── discord/                    # fila, embeds e cliente HTTP do webhook
├── listener/                   # entrada/saída, chat, morte, conquistas
├── security/                   # Sanitizer e FloodGuard
└── util/                       # JSON e cores
```

---

<div align="center">
Feito por <b>MylerMC</b>
</div>
