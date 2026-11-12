# Chuva na BR (Godot 4)

Jogo relaxante de dirigir em pixel art: carro antigo de molas macias, estrada chuvosa, rádio e nenhum game over.

## Abrir

1. Instale o Godot 4.5 ou mais novo (versão padrão, sem .NET).
2. No gerenciador de projetos, clique em **Importar** e escolha o `project.godot` desta pasta.
3. Aperte F5 para jogar.

## Controles

| Ação | Tecla |
|---|---|
| Girar a chave | Enter ou clique |
| Virar | setas esquerda/direita ou A/D (ou clique nos lados da tela) |
| Velocidade de cruzeiro | setas cima/baixo ou W/S |
| Câmera interna/externa | V |
| Trocar de estação | R (ou clique no rádio do painel) |
| Piloto automático | P |
| Buzina | B |
| Som | M |
| Tela cheia | F11 |

## Estrutura

- `main.tscn`: cena única. `World` desenha a estrada, `Cockpit` a cabine, `Post` aplica a paleta e `HUD` mostra o placar.
- `scripts/game.gd`: estado, pista, física da suspensão, trânsito, clima, entrada e áudio.
- `scripts/world.gd`: céu, estrada pseudo-3D, sprites, trânsito e o carro na câmera externa.
- `scripts/cockpit.gd`: gotas, limpadores e tudo que se mexe dentro da cabine.
- `scripts/hud.gd`: placar, avisos, painel de velocidade e tela inicial.
- `shaders/palette.gdshader`: reduz o quadro a 55 cores com pontilhado.
- `assets/sprites`: PNGs em 2x (uma unidade lógica = 2 pixels). Edite num editor de pixel art e o jogo usa a nova versão.
- `assets/audio`: três estações de rádio em loop, chuva, motor e efeitos.
- `assets/fonts/Estrada2P.ttf`: fonte Estrada 2P, versão da Press Start 2P com as maiúsculas acentuadas redesenhadas em altura cheia (licença SIL Open Font, em `assets/fonts/OFL.txt`).

A tela interna é 768x432, ampliada sem filtro. Os scripts desenham em unidades lógicas de 384x216.
