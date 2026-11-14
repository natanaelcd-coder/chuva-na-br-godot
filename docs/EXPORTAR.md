# Como exportar o jogo (Windows, Linux e Web)

Requisitos: Godot 4.5.1 e os export templates 4.5.1 (Editor > Gerenciar templates de exportação, ou
`~/.local/share/godot/export_templates/4.5.1.stable/`).

## Reexportar com 1 comando

```
G=caminho/do/Godot_v4.5.1-stable_linux.x86_64
mkdir -p builds/windows builds/linux builds/web
$G --headless --path . --import
$G --headless --path . --export-release "Windows Desktop" builds/windows/ChuvaNaBR.exe
$G --headless --path . --export-release "Linux" builds/linux/ChuvaNaBR.x86_64
$G --headless --path . --export-release "Web" builds/web/index.html
```

Depois, zipe cada pasta (`ChuvaNaBR-windows.zip`, `ChuvaNaBR-linux.zip`, `ChuvaNaBR-web.zip`).
A pasta `builds/` fica fora do git. Os presets estão em `export_presets.cfg`
(qa/, docs/, tools/, tests/, web/ e .claude/ são excluídos do pacote).

## Subir a versão web no itch.io (privado)

1. Crie um projeto em itch.io, "Kind of project": HTML.
2. Envie `ChuvaNaBR-web.zip` e marque "This file will be played in the browser".
3. Em Visibilidade, escolha "Restricted" (ou "Draft") e compartilhe o link secreto/senha com os amigos.
4. A versão web foi exportada sem threads, então funciona em qualquer host estático.
   O som só começa depois do primeiro clique na tela (regra dos navegadores).

## Avisos

- Windows: o .exe não é assinado, então o SmartScreen mostra "O Windows protegeu o computador".
  Clique em "Mais informações" e depois "Executar assim mesmo".
- Linux: dê permissão de execução (`chmod +x ChuvaNaBR.x86_64`) depois de extrair o zip.
- O pacote é grande (~120 MB no .exe) porque o motor e os recursos vão embutidos num único arquivo.
