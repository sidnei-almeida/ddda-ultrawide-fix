<p align="center"><img src="assets/banner.png" alt="Dragon's Dogma: Dark Arisen Ultrawide Fix" width="100%"></p>

<h1 align="center">Dragon's Dogma: Dark Arisen Ultrawide Fix</h1>

<p align="center"><b>Preencha seu monitor 21:9 ou 32:9 e mantenha o HUD exatamente onde a Capcom colocou. Um comando, e é só jogar.</b><br>
Linux · Proton · Steam Deck · Windows (manual)</p>

<p align="center">
  <img alt="Linux" src="https://img.shields.io/badge/Linux-suportado-3dffb0?style=for-the-badge&logo=linux&logoColor=white&labelColor=0d1a1f">
  <img alt="Proton" src="https://img.shields.io/badge/Proton-GE%2011%20testado-5ad8ff?style=for-the-badge&logo=steam&logoColor=white&labelColor=0d1a1f">
  <img alt="21:9 e 32:9" src="https://img.shields.io/badge/21%3A9%20%C2%B7%2032%3A9-sem%20faixas%20pretas-5ad8ff?style=for-the-badge&labelColor=0d1a1f">
  <img alt="Licença MIT" src="https://img.shields.io/badge/licen%C3%A7a-MIT-ff5a3c?style=for-the-badge&labelColor=0d1a1f">
</p>

<p align="center"><i>"Levante-se, Arisen. O mundo é mais largo do que você imaginava."</i></p>

<p align="center">🇺🇸 <b><a href="README.md">Read in English →</a></b></p>

---

## O que é isso?

Dragon's Dogma: Dark Arisen é um port de 2016 de um jogo de console de 2012. Ele deixa você escolher 3440x1440, mas aí **corta o campo de visão vertical** (você vê menos céu e menos chão do que quem joga em 16:9) e **estica o HUD** pela largura inteira, de modo que minimapa, barra de vida e mensagens dos pawns ficam espalhados pelas bordas.

**Este instalador resolve os dois com um comando.** Ele instala o [DDDAFix](https://github.com/Lyall/DDDAFix) do Lyall, o patch em tempo de execução que dá ao jogo um campo de visão correto em qualquer proporção e mantém o HUD numa caixa 16:9 centralizada, e cuida da única coisa a mais que o Linux precisa: a opção de inicialização da Steam que permite ao Proton carregá-lo. Nenhum arquivo do jogo é modificado.

- 🖥️ **De ponta a ponta.** O mundo preenche o monitor com campo de visão Hor+ de verdade: você vê mais pros lados, nunca menos em cima e embaixo.
- 🎯 **HUD em 16:9, onde ele pertence.** Minimapa, vida, stamina, falas dos pawns e paleta de ações ficam na caixa centralizada para a qual o jogo foi desenhado. Sem ícones esticados, sem elementos fora da tela.
- 🪟 **Borderless fullscreen.** Deixe o jogo em *Windowed* e ele cobre a tela sem borda, com alt-tab instantâneo.
- 🐧 **Linux em primeiro lugar.** Acha o jogo em todas as bibliotecas da Steam, escreve a opção `WINEDLLOVERRIDES` por você e convive com ReShade, gamescope e mods baseados em `dinput8` que já estiverem na linha.
- 🧰 **Zero hex editing.** O `DDDA.exe` nunca é tocado. Desinstale com uma flag e a pasta volta ao original.

---

## Screenshot

<p align="center"><img src="assets/gameplay-hud-16-9.jpg" alt="Gameplay em 3440x1440: a cena preenche o monitor enquanto minimapa, barra de vida e paleta de ações ficam dentro da área 16:9 centralizada." width="100%"><br><sub>3440x1440 no Linux (GE-Proton 11). A cena preenche o monitor; minimapa, barra de vida, caixa de tutorial e paleta de ações ficam dentro da área 16:9 centralizada.</sub></p>

---

## Início rápido

```sh
curl -fsSL https://raw.githubusercontent.com/sidnei-almeida/ddda-ultrawide-fix/main/install.sh | bash
```

| Passo | O que fazer |
|:---:|---|
| 1 | **Feche a Steam** (para o script conseguir gravar a opção de inicialização) e rode o comando acima. |
| 2 | Abra a Steam e inicie o jogo. Em **Options → Graphics**, escolha a resolução nativa do seu monitor e o modo *Windowed* (o fix transforma em borderless fullscreen). |
| 3 | **Jogue.** O `DDDAFix.log` aparece ao lado do `DDDA.exe` na primeira vez que o fix carrega. |

Ou clone o repositório e rode `./install.sh`. Nos dois casos o script é idempotente: rode de novo depois de uma atualização do jogo, de uma reinstalação ou de uma troca de Proton e ele só corrige o que estiver faltando.

---

## O que o script faz

1. **Verifica o payload.** Cada arquivo é conferido contra `payload/SHA256SUMS` antes de qualquer cópia.
2. **Acha o jogo.** Lê o `installdir` do `appmanifest_367500.acf` em todas as bibliotecas da Steam (instalação nativa, Flatpak e Snap), depois procura em Heroic, Lutris e Bottles. Use `--path` se o jogo estiver num lugar incomum.
3. **Instala o DDDAFix.** `winmm.dll` (Ultimate ASI Loader) e `DDDAFix.asi` vão para o lado do `DDDA.exe`. Um `winmm.dll` que já exista e não seja o nosso vira `winmm.dll.bak`. Seu `DDDAFix.ini` é mantido se você já tiver ajustado.
4. **Configura a opção de inicialização da Steam.** O Proton tem o próprio `winmm.dll`, então o jogo precisa ser instruído a preferir o da pasta. O script mescla `winmm` na lista `WINEDLLOVERRIDES` que você já tiver, então o `d3d9` do ReShade, um loader `dinput8`, as flags do gamescope e o resto da linha sobrevivem. Se a Steam estiver aberta, ele imprime a linha exata para colar.

```
./install.sh [--path <pasta do jogo>]... [--uninstall] [--dry-run] [--no-launch-options] [--reset-ini]

  --path DIR            Pasta que contém o DDDA.exe (pode repetir).
  --uninstall           Remove o fix e a opção de inicialização, restaura um winmm.dll de backup.
  --dry-run             Mostra o que seria feito sem alterar nada.
  --no-launch-options   Não mexe nas opções de inicialização da Steam.
  --reset-ini           Sobrescreve o DDDAFix.ini com os padrões do repositório.
```

---

## Instalação manual (Linux ou Windows)

Copie os três arquivos de [`payload/`](payload) para a pasta que contém o `DDDA.exe`:

```
DDDA/
├── DDDA.exe
├── winmm.dll        ← Ultimate ASI Loader
├── DDDAFix.asi      ← o fix
└── DDDAFix.ini      ← as configurações
```

No Windows é só isso. No Linux, adicione também a opção em Steam → Dragon's Dogma: Dark Arisen → Propriedades → Opções de inicialização:

```
WINEDLLOVERRIDES="winmm=n,b" %command%
```

Se já tiver uma lista de overrides, acrescente `winmm` nela: `WINEDLLOVERRIDES="d3d9,winmm=n,b" %command%` (ReShade), `WINEDLLOVERRIDES="d3d9,dinput8,winmm=n,b" %command%` (ReShade mais um loader `dinput8`).

---

## Configurações

Tudo fica no `DDDAFix.ini` da pasta do jogo. As mudanças valem na próxima abertura, sem reinstalar.

| Seção | Padrão | O que faz |
|---|:---:|---|
| `[Fix HUD]` | ligado | Mantém o HUD numa caixa 16:9 centralizada e corrige elementos esticados. |
| `[Fix FOV]` | ligado | Campo de visão Hor+ em qualquer proporção. |
| `[Borderless Windowed Mode]` | ligado | *Windowed* nas opções do jogo vira borderless fullscreen. |
| `[Disable Pause on Focus Loss]` | desligado | Mantém o jogo rodando quando você dá alt-tab. Útil com segundo monitor. |
| `[Raise Framerate Cap]` | desligado | Sobe o limite "variable" de 150 para 1000 fps. A física do jogo depende do frame rate, então deixe desligado a menos que saiba o que está fazendo. |

---

## Indo além: supersampling com gamescope

Um motor de 2012 em 3440x1440 cintila em grama, cabelo e cercas, e o jogo não tem anti-aliasing temporal. A resposta mais limpa no Linux é renderizar acima do monitor e deixar o gamescope reduzir. Coloque isto nas opções de inicialização (mantendo a lista de overrides que você já tem):

```
WINEDLLOVERRIDES="winmm=n,b" gamescope -W 3440 -H 1440 -w 4300 -h 1800 -r 100 -f -- %command%
```

`-W/-H` é o monitor, `-w/-h` o tamanho de renderização (aqui 1,25x) e `-r` a taxa de atualização. No jogo, escolha a resolução de renderização (4300x1800) nas opções gráficas. O DDDAFix calcula tudo a partir da resolução em que o jogo roda, então HUD e FOV continuam corretos. 1,5x (`-w 5160 -h 2160`) fica ainda melhor, mas o jogo é um processo DirectX 9 de 32 bits: cada buffer conta contra um limite de 4 GB, e com packs de textura grandes 1,25x é a escolha mais segura.

---

## Problemas comuns

| Problema | Solução |
|---|---|
| **Não aparece `DDDAFix.log` na pasta do jogo** | O fix nunca carregou. No Linux, falta a opção de inicialização ou a Steam estava aberta quando o instalador rodou: rode `./install.sh` de novo com a Steam fechada, ou cole a linha à mão. Confira que o `winmm.dll` está ao lado do `DDDA.exe`, não dentro de `nativePC`. |
| **Ainda tem faixas pretas ou HUD esticado** | O jogo está numa resolução 16:9. Escolha a resolução nativa do monitor em Options → Graphics. |
| **A janela do jogo tem borda ou fica num canto** | Escolha *Windowed* no modo de exibição do jogo. O DDDAFix transforma em borderless fullscreen. |
| **O jogo pausa quando dou alt-tab** | Coloque `Enabled = true` em `[Disable Pause on Focus Loss]` no `DDDAFix.ini`. |
| **O jogo crasha na tela de título com mods instalados** | Mods de vídeo da tela de título com áudio 5.1 (por exemplo *Dark Arisen Title Screen Revival*) derrubam o XAudio2 no Proton. Desative o mod ou restaure os arquivos originais de `nativePC/movie/title`. |
| **Crash instantâneo com um mod loader `dinput8.dll` (tweaks de câmera, Arcs loader)** | O hook de hotkeys dele falha no Proton e pula para um ponteiro nulo. Coloque `enabled = off` em `[hotkeys]` no `dinput8.ini`; o resto do loader continua funcionando. |
| **Crashes em áreas cheias com packs de textura grandes** | O jogo é de 32 bits, com teto de 4 GB (o `DDDA.exe` da Steam já tem a flag Large Address Aware). Reduza a resolução de renderização, tire o supersampling ou remova o pack mais pesado. |
| **Uma atualização do jogo quebrou o fix** | O DDDAFix acha os pontos de patch por padrão de bytes, então atualizações costumam sobreviver. Se o `DDDAFix.log` mostrar "pattern not found", abra uma issue com o log. |

<p align="center"><a href="https://github.com/sidnei-almeida/ddda-ultrawide-fix/issues"><img alt="Precisa de ajuda? Abra uma issue" src="https://img.shields.io/badge/Precisa%20de%20ajuda%3F-Abra%20uma%20issue-ff5a3c?style=for-the-badge&labelColor=0d1a1f&logo=github&logoColor=white"></a></p>

---

## Perguntas frequentes

**Por que não o AgDrag?** O [AgDrag](https://github.com/Kaldaien/AgDrag) do Kaldaien (2016) costuma ser citado como "o" fix de ultrawide, mas o propósito dele é outro: manter o jogo renderizando em segundo plano e bloquear algumas teclas, e o suporte a proporção dele é um "map fix" experimental. Ele também traz um `d3d9.dll` próprio, que colide com ReShade e ENB. O DDDAFix é quem faz o trabalho de FOV e HUD de verdade, e convive com tudo.

**O HUD pode ir para as bordas da tela em vez de ficar em 16:9?** O jogo desenha o HUD como um único canvas 16:9, e cada widget calcula a transformação de tela pela mesma rotina. Prototipamos ancorar widgets individuais (minimapa, paleta de ações, mensagens dos pawns) nas bordas, engatando nessa rotina e identificando cada widget pelo nome da classe em tempo de execução. Funciona, mas o terreno do minimapa é desenhado por outro caminho e o resultado ficou grande demais e fora de lugar. O HUD 16:9 centralizado é para o que o jogo foi desenhado, e é o que este projeto entrega.

**Funciona com ReShade?** Sim. O ReShade instala como `d3d9.dll`; adicione na lista de overrides (`WINEDLLOVERRIDES="d3d9,winmm=n,b"`). O instalador faz essa mescla por você.

**Funciona no Windows?** Sim: copie os três arquivos do payload, sem opção de inicialização. Não foi testado aqui.

**Steam Deck?** Mesmos arquivos, mesma opção de inicialização. A tela 16:10 do Deck também se beneficia do fix de FOV.

---

## Desinstalar

```sh
./install.sh --uninstall
```

Remove `winmm.dll`, `DDDAFix.asi`, `DDDAFix.ini` e `DDDAFix.log`, restaura o `winmm.dll.bak` se existir e tira o `winmm` das opções de inicialização (o resto da linha é mantido).

## Relate seus resultados

Abra uma issue com o [template de resultados](.github/ISSUE_TEMPLATE/results.md): resolução, sistema, versão do Proton, o que funciona e um print do que não funciona.

---

## Como funciona

Você não precisa desta parte para usar o fix.

```
Steam ──► Proton ──► DDDA.exe
                        │  WINEDLLOVERRIDES="winmm=n,b" faz o jogo carregar o winmm.dll da pasta
                        ▼
                    winmm.dll        Ultimate ASI Loader: repassa as chamadas reais do winmm e carrega *.asi
                        ▼
                    DDDAFix.asi      espera o InjectionDelay e aplica patches na memória do jogo:
                        │              · contas de proporção e FOV (Hor+ em qualquer razão)
                        │              · transformação do HUD: escala para a largura 16:9, desloca para o centro
                        │              · janela sem borda, pausa ao perder foco, limite de frame rate
                        ▼
                    DDDAFix.log      cada ponto de patch encontrado, como DDDA.exe+offset
```

O DDDAFix localiza cada ponto de código por padrão de bytes em tempo de execução (com hooks de meio de função do [safetyhook](https://github.com/cursey/safetyhook)), então o executável em disco não é tocado e a verificação de arquivos da Steam continua passando.

## Testado em

| | |
|---|---|
| Resolução | 3440x1440 (21:9), 100 Hz |
| Sistema | Arch Linux (Omarchy), Hyprland |
| GPU | Intel Arc B580 (DXVK) |
| Proton | GE-Proton 11-7 |
| Jogo | Build 2364871 da Steam |
| DDDAFix | v0.9.1 (`payload/VERSION`) |
| Junto com | ReShade 6 (`d3d9.dll`), supersampling com gamescope, mods de textura em `nativePC` |

32:9 e 16:10 usam os mesmos caminhos de código do DDDAFix, mas não foram testados aqui. [Relate](#relate-seus-resultados), por favor.

## Créditos

- **[Lyall/DDDAFix](https://github.com/Lyall/DDDAFix)** (MIT): o fix em si. `payload/DDDAFix.asi` é a release v0.9.1 sem modificações.
- **[ThirteenAG/Ultimate-ASI-Loader](https://github.com/ThirteenAG/Ultimate-ASI-Loader)** (MIT): `payload/winmm.dll`, como vem naquela release.
- As comunidades [PCGamingWiki](https://www.pcgamingwiki.com/wiki/Dragon%27s_Dogma:_Dark_Arisen) e WSGF, por documentarem o comportamento ultrawide do jogo.

## Licença

O instalador e a documentação são [MIT](LICENSE). DDDAFix e Ultimate ASI Loader mantêm as próprias licenças MIT (`payload/DDDAFix_LICENSE.md`, `payload/UltimateASILoader_LICENSE.md`). Dragon's Dogma: Dark Arisen pertence à Capcom.
