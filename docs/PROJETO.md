# Chuva na BR — documento do projeto (para continuar em outro computador ou com outra IA)

Este arquivo reúne o conceito, o estado atual, a arquitetura, as ferramentas e as decisões tomadas até aqui.
Leia junto com `README.md` (como abrir e jogar), `scripts/features/README.md` (como criar uma feature),
`docs/brainstorm.md` (as 24 ideias originais) e `qa/RUBRIC.md` (como o jogo é avaliado).

---

## 1. Conceito

**Chuva na BR** é um jogo de dirigir **relaxante**, em **pixel art retrô** (pseudo-3D no estilo OutRun), dentro de um
**carro brasileiro antigo**. A inspiração inicial foi uma imagem: a vista de dentro de um carro velho, chuva no para-brisa,
rádio ligado, penduricalhos no retrovisor, estrada brasileira à frente.

Pilares (o que não pode se perder):

1. **Sem pressa e sem punição.** Não existe game over. Bater, cair em buraco ou sair da pista só dá um tranco,
   um aviso gentil e perda de "pontos" que nem importam. A graça é passar o tempo.
2. **Brasilidade afetiva.** BR-116, estrada de terra de sítio, posto de beira de estrada, pastel e caldo de cana,
   vó de crochê no banco do passageiro, cachorro caramelo, festa junina, ipês, araucárias, adesivo "É velho mas tá pago",
   rádio AM/FM com locutor de interior. Nada de marcas reais.
3. **Sensação de carro velho.** Suspensão macia de mola (cada carro com personalidade), volante lento,
   ondulações e cristas na pista (o carro pula em alta velocidade), carroceria que rola para fora da curva.
4. **O rádio é personagem.** Três estações com locutores, recados de ouvintes, previsão do tempo, hora certa,
   propagandas e músicas; fita K7 no Besouro.
5. **Coleção suave.** Caderneta de figurinhas, passaporte de paradas, diário de viagens com cartão-postal,
   hodômetro por carro, garagem com cores e penduricalhos — progresso sem obrigação.

Público: quem quer um jogo para relaxar alguns minutos ou deixar rodando (há piloto automático e modo descanso).

## 2. O que existe hoje (versão 4)

- **3 carros:** Besouro 1973 (Fusca: molas macias, volante lento, fita K7), Picape Rural 1979 (cabine alta, quica,
  3 marchas), Sedã GT 1989 (baixo, firme, 140 km/h, 5 marchas, painel digital). Cada um com cabine própria (vista interna)
  e vista traseira (câmera externa, tecla V), e várias cores na garagem.
- **3 estradas:** Estrada do Sítio (terra, mão dupla, ultrapassagem pela contramão, pasto, vacas, galinhas, porteiras),
  BR-116 (asfalto, faixas, caminhões, posto, guard-rail, cidades), Rodovia Expressa (concreto, 4 faixas, pórticos,
  pedágio, coqueiros, mar ao fundo).
- **Clima:** sol, chuva, variável (o tempo muda durante a viagem: nublando, pancada, garoa, arco-íris).
- **Hora:** dia, entardecer, noite, ciclo completo.
- **Física:** suspensão com mola e amortecedor por carro (corpo, arfagem, rolagem), cristas que fazem o carro sair do chão,
  buracos, poças (aquaplanagem leve), lombadas, aceleração/frenagem/troca de marcha, curvas que empurram para fora.
- **Piloto em 3 modos (tecla P):** DESLIGADO (você acelera com ↑, freia com ↓, solta e o carro desacelera; sem segurar faixa),
  ASSISTIDO (cruzeiro, mantém a faixa e a distância; você escolhe a faixa) e LIGADO (dirige sozinho: desvia de buracos,
  ultrapassa, para no posto, alivia antes das cristas). Mexer no volante no LIGADO passa para ASSISTIDO.
- **Trânsito:** carros, vans, motos, caminhões (baú, boiadeiro), ônibus, trator com tratorista, carroça; contramão nas
  estradas de mão dupla.
- **Mundo vivo:** eventos (boiada, balão, helicóptero, periquitos, vaga-lumes, LED, romeiros…), épocas do ano
  (festa junina, Natal, ipês, verão), frases na paisagem, cidades de chegada ("Chegamos a Taboão!"), placas e pórticos.
- **Paradas:** posto, venda e loja de conveniência (cena própria, cardápio de lanches, passaporte), com frentista e
  atendentes animados. Entra-se encostando devagar à direita ou com Enter perto.
- **Passageiro:** vó (crochê, cochila com direção suave, acorda no buraco) ou caramelo.
- **Rádio:** Serra FM (Seu Arlindo), Litoral FM (DJ Caiçara), Noite AM (Valdo); 160+ falas gravadas (ElevenLabs),
  uma música nova com letra por estação + músicas sintéticas antigas; fita K7 com lados A/B.
- **Coleção e memória:** caderneta (64 figurinhas), diário com cartão-postal ao fim da viagem, modo foto (F),
  hodômetro por carro, prêmios/penduricalhos, garagem.
- **Conforto:** ajustes (balanço da câmera, tremor, buracos, trânsito, volumes, avisos), viagem de hoje (roteiro diário),
  código da viagem (compartilhar a mesma viagem), modo descanso, manobras elogiadas ("Desvio limpo").

## 3. Como abrir e rodar

- Godot **4.5** (versão padrão, sem .NET). Abrir `project.godot` e apertar F5.
- Tudo é GDScript; não há dependências externas para jogar.
- Controles: ver `README.md`.

## 4. Arquitetura (resumo)

- `main.tscn` — cena única. Nós: `World` (céu, estrada, sprites), `Cockpit` (cabine), `Post` (shader de paleta),
  `HUD`, `Menu`, e as features carregadas automaticamente.
- `scripts/game.gd` — estado (menu/drive/pause/parada/foto), geração da pista (segmentos), física, trânsito,
  piloto automático (`drive_mode` 0/1/2, `set_mode`, `set_auto`), clima, entrada, áudio, sinais para as features.
- `scripts/catalog.gd` — **todos os números** de carros, estradas, clima, hora, cidades; mudar a personalidade de um
  carro é mexer aqui (spring_k/c, pitch, roll, top, marchas, wheel_x, body_h…).
- `scripts/world.gd` — desenho pseudo-3D (projeção dos segmentos), céu/montanhas em camadas, sprites, carro externo.
- `scripts/cockpit.gd` — cabine por carro (volante, ponteiros, rádio, adesivos, chuva e limpadores).
- `scripts/hud.gd`, `scripts/menu.gd` — painel, avisos, menu com prévia ao vivo, pausa, telas extras.
- `scripts/anim_tex.gd` — sprites animados (tiras de quadros com fase por instância).
- `scripts/radio_vozes.gd` — índice texto → arquivo de voz.
- `scripts/features/*.gd` — cada pacote de funcionalidade é um Node carregado sozinho (ordem alfabética), que se liga
  aos sinais do jogo (`trip_started`, `trip_ended`, `seg_passed`, `hole_hit`, `bumped`, `jumped`…) e a ganchos de
  desenho (`draw_sky`, `draw_car`, `draw_cabin_over`, `drive_key`, `menu_info`…). Regras em `scripts/features/README.md`.
- `shaders/palette.gdshader` — reduz o quadro a 55 cores com pontilhado (identidade visual).
- Resolução lógica 384x216 desenhada em 768x432 (sprites em 2x).
- Salvamento: `user://viagem.cfg` via `g.store_get/store_set` (não salva quando há `Engine meta "test_seed"`).

## 5. Arte e áudio — de onde vêm

- **Arte original por código:** `tools/art/build_art.js` (Node + Playwright desenhando em canvas, reaproveitando
  `web/chuva-na-br.html`, o protótipo HTML original). Gera `assets/sprites/*.png`.
- **Arte nova por IA (PixelLab):** a maior parte dos sprites hoje veio da PixelLab, no estilo dos nossos sprites
  (endpoint `/generate-with-style-v2` com nossos PNGs como referência de estilo). As listas `tools/art/ia_*.txt`
  dizem quais sprites são de IA — `build_art.js` **não** sobrescreve esses. Brutos escolhidos ficam em `docs/ia/`.
  Scripts de encaixe/recorte: `tools/ai/fit_estrada.py`, `tools/ai/pers2_build.py`, `tools/art/carros_ia.py`,
  `tools/art/cabines_ia.py`, `tools/art/cenario_*.py`, `tools/art/placas_*.py`.
  Textos em placas são sempre escritos pelo jogo/fonte (a IA desenha a placa vazia).
- **Áudio original:** `tools/audio/build_music.js` (síntese no Chromium + ffmpeg).
- **Vozes, efeitos e músicas novas (ElevenLabs):** `tools/ai/eleven.py` (TTS e efeitos), `tools/ai/vozes_radio.py`
  (roteiros do rádio; só gera o que falta), API de música para as 3 músicas novas (`assets/audio/musica/`).
  Vozes usadas: Serra FM = "Locutor Serra FM" (Rômulo Franklin, id HR2TRGmi4QbMsO5omv7l); Litoral FM e Noite AM com
  outras duas vozes brasileiras adicionadas à conta (ids em `scripts/radio_vozes.gd`/`tools/ai/vozes_radio.py`).
- **Retro Diffusion:** testado (`tools/ai/rd.py`); a PixelLab foi escolhida pelo custo/qualidade.
- Chaves de API **não** estão no projeto. Os scripts leem `PIXELLAB_API_KEY`, `ELEVENLABS_API_KEY`,
  `RETRODIFFUSION_API_KEY` do ambiente (ou um proxy injeta). Em novembro de 2026 os créditos da PixelLab acabaram.
- Fonte: Estrada2P (Press Start 2P modificada, OFL) em `assets/fonts/`.

## 6. Testes e avaliação

Godot headless/xvfb (o render por software é lento; testes de captura precisam de `xvfb-run` e `--rendering-driver opengl3`).

- `tests/combos.gd` — 27 combinações carro×estrada×clima: piloto automático sem batidas, sem NaN (headless, ~20 min).
- `tests/feat_*.gd` — um por pacote (radio, vozes, piloto, paradas, estrada, garagem, conforto, mola, mundo, colecao);
  cada um imprime `FAILS: N`.
- `tests/test_drive.gd` + `qa/run_qa.sh` — métricas de dirigibilidade em `qa/metrics/latest.json`.
- `tests/cap_*.gd`, `pers*_capturas.gd`, `captura_placas.gd`, `showcase.gd` — só capturas de tela.
- `qa/RUBRIC.md` — rubrica de nota (dirigibilidade 30%, suspensão 20%, pista 20%, feedback 15%, fluxo 10%, visual 5%).
  Histórico em `qa/scores.csv` e `qa/reports/round-NN.md`: 4.7 → … → 8.6 (rodada 9) → **8.8 (rodada 10)**.

Exemplo:
```
godot --headless --path . --import
godot --headless --path . --fixed-fps 60 --audio-driver Dummy --script res://tests/combos.gd
xvfb-run -a godot --path . --fixed-fps 60 --rendering-driver opengl3 --audio-driver Dummy --script res://tests/feat_paradas.gd -- /tmp/saida
```

## 7. Exportar (quando quiser)

`export_presets.cfg` já tem Windows, Linux e Web. Passo a passo em `docs/EXPORTAR.md`. Por decisão do dono,
por enquanto o jogo é testado só dentro do Godot.

## 8. Histórico resumido

1. Protótipo HTML (`web/chuva-na-br.html`): cabine do Fusca, chuva, rádio.
2. Física com suspensão, ondulações, câmera externa (V), resolução maior com pixel art.
3. Migração para Godot 4.5; lista de artes a encomendar; agente de QA com rodadas de nota (4.7 → 8.6).
4. Versão 2: 3 carros, 3 estradas, clima e hora, menu com prévia.
5. Brainstorm (24 ideias) → 7 pacotes implementados (conforto, rádio, paradas/memórias, coleção, garagem, estrada, mundo vivo).
6. Rodada 10: mola mais firme, cristas com pulo, rolagem corrigida (nota 8.8).
7. Vozes do rádio e efeitos (ElevenLabs); arte nova completa (PixelLab): cabines, trânsito, beira de estrada,
   personagens animados, bichos, carros externos, céu/montanhas, menu, placas, lanches.
8. Músicas novas por estação; piloto em 3 modos.

## 9. Ideias e pendências

- Trocar as músicas sintéticas antigas que sobraram nas rádios (cada estação tem 4; só 1 é nova).
- Bandeirinhas sem a cor amarela (geradas reaproveitando um bruto; dá para gerar de novo quando houver crédito).
- Rodada 11 de QA com toda a arte e áudio novos (rubrica em `qa/RUBRIC.md`).
- Controle de videogame (gamepad) e controles de toque para a versão web.
- Ouvir e aprovar as 3 músicas novas e a pronúncia de "á-éme", "bê-érre cento e dezesseis", "dijêi".
- Ideias não feitas ou para aprofundar estão em `docs/brainstorm.md`.

## 10. Convenções

- Textos do jogo em português do Brasil, maiúsculas na fonte do jogo.
- Commits em português. Repositório: GitHub `natanaelcd-coder/chuva-na-br-godot` (branch `main`).
- Não colocar chaves de API no repositório.
- Sprites de IA: sempre registrar o nome no `tools/art/ia_*.txt` correspondente.
- Toda feature nova: um arquivo em `scripts/features/` + um teste `tests/feat_*.gd`.
