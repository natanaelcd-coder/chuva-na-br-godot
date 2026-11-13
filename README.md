# Chuva na BR (Godot 4)

Jogo relaxante de dirigir em pixel art: escolha o carro, a estrada, o clima e a hora, ligue o rádio e vá sem pressa. Nenhum game over.

## Abrir

1. Instale o Godot 4.5 ou mais novo (versão padrão, sem .NET).
2. No gerenciador de projetos, clique em **Importar** e escolha o `project.godot` desta pasta.
3. A## A viagem

No menu você monta a viagem e vê uma prévia ao vivo dela atrás:

| Opção | Escolhas |
|---|---|
| Carro | **Besouro 1973** (molas macias, volante lento), **Picape Rural 1979** (cabine alta, feixe de molas duro, direção pesada, 3 marchas), **Sedã GT 1989** (baixo, firme, 140 km/h, 5 marchas, conta-giros) |
| Estrada | **Estrada do Sítio** (terra, mão dupla, cafezal, pasto, porteiras; ultrapasse pela contramão olhando quem vem), **BR-116** (duplicada, 3 faixas, caminhões, posto, guard-rail), **Rodovia Expressa** (concreto, 4 faixas, mureta, luz contínua, pórticos, pedágio) |
| Clima | Sol (céu aberto, poeira na terra) ou Chuva (limpador, poças, lama) |
| Hora | Dia, Entardecer, Noite ou Dia inteiro (o tempo passa) |

As escolhas e o recorde de cada estrada ficam salvos.

## Controles

| Ação | Tecla |
|---|---|
| Menu: escolher e trocar | setas (ou clique nas setas e nos valores) |
| Menu: pegar a estrada | Enter (ou clique no botão) |
| Pausa (continuar, mudar a viagem, som, modo descanso, ajustes, sair) | Esc |
| Menu: viagem de hoje, ajustes, código da viagem | linha de baixo do menu (setas e Enter) |
| Virar | setas esquerda/direita ou A/D (ou clique nos lados da tela) |
| Velocidade de cruzeiro | setas cima/baixo ou W/S |
| Câmera interna/externa | V |
| Trocar de estação | R (ou clique no rádio do painel) |
| Piloto automático | P |
| Buzina | B |
| Seta (esquerda/direita) | Q / E |
| Som | M |
| Tela cheia | F11 |

| Tela cheia | F11 |

## Estrutura

- `main.tscn`: cena única. `World` desenha a estrada, `Cockpit` a cabine, `Post` aplica a paleta, `HUD` mostra o placar e `Menu` é o planejador da viagem e a pausa.
- `scripts/catalog.gd`: carros, estradas, clima e hora. Toda a diferença entre as escolhas está nesses números.
- `scripts/menu.gd`: menu principal com prévia ao vivo e tela de pausa.
- `scripts/game.gd`: estado, pista, física da suspensão, trânsito, clima, entrada e áudio.
- `scripts/world.gd`: céu, estrada pseudo-3D, sprites, trânsito e o carro na câmera externa.
- `scripts/cockpit.gd`: gotas, limpadores e tudo que se mexe dentro da cabine, com o layout de cada carro.
- `tools/art/`: gerador da arte nova (`node tools/art/build_art.js`), reaproveitando os desenhos da versão web.
- `tests/showcase.gd` e `tests/combos.gd`: capturas de várias combinações e um teste que dirige todos os carros em todas as estradas.
- `scripts/hud.gd`: placar, avisos, painel de velocidade e tela inicial.
- `shaders/palette.gdshader`: reduz o quadro a 55 cores com pontilhado.
- `assets/sprites`: PNGs em 2x (uma unidade lógica = 2 pixels). Edite num editor de pixel art e o jogo usa a nova versão.
- `assets/audio`: três estações de rádio em loop, chuva, motor e efeitos.
- `assets/fonts/Estrada2P.ttf`: fonte Estrada 2P, versão da Press Start 2P com as maiúsculas acentuadas redesenhadas em altura cheia (licença SIL Open Font, em `assets/fonts/OFL.txt`).

A tela interna é 768x432, ampliada sem filtro. Os scripts desenham em unidades lógicas de 384x216.
