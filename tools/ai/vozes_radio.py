#!/usr/bin/env python3
"""Locução do rádio pela ElevenLabs: roteiros, geração e índice.

    python3 tools/ai/vozes_radio.py            # gera só o que falta e reescreve o índice
    python3 tools/ai/vozes_radio.py --dry      # só conta caracteres e mostra o que falta

Cada fala tem o texto da tela (exatamente o que o letreiro do jogo mostra) e o texto falado (números por extenso,
siglas soletradas). O mp3 bruto fica em BRUTO (fora do repositório); o .ogg normalizado vai para assets/audio/voz/.
O índice sai em scripts/radio_vozes.gd (um Dictionary em GDScript, para ir junto no export).
"""
import json, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets/audio/voz")
BRUTO = os.environ.get("BRUTO", os.path.join(ROOT, ".godot", "voz_bruto"))   # fora do git
INDEX = os.path.join(ROOT, "scripts/radio_vozes.gd")

# uma voz por estação: Seu Arlindo (Serra FM), a DJ Caiçara (Litoral FM), Valdo Voz de Veludo (Noite AM)
VOZES = [
    {"id": "HR2TRGmi4QbMsO5omv7l", "nome": "Rômulo Franklin", "args": ["--stability", "0.5", "--style", "0.3", "--speed", "0.95"]},
    {"id": "xMGbstDe7gGBMg3DqxOc", "nome": "Alice", "args": ["--stability", "0.4", "--style", "0.45"]},
    {"id": "uMk2ijhneJaRm2sKMgdi", "nome": "Daniel Mercer", "args": ["--stability", "0.55", "--style", "0.25", "--speed", "0.9"]},
]
EST = ["serra", "litoral", "noite"]

# ---------------------------------------------------------------- roteiros: (tela, fala)
SLOGANS = [
    [("SERRA FM 98,7: A RÁDIO QUE SOBE A SERRA COM VOCÊ.", "Serra FM, noventa e oito, sete: a rádio que sobe a serra com você."),
     ("VOCÊ ESTÁ OUVINDO A SERRA FM, A RÁDIO DO CAFÉ PASSADO NA HORA.", "Você está ouvindo a Serra FM, a rádio do café passado na hora."),
     ("SERRA FM: DE CURVA EM CURVA, DE MODA EM MODA.", "Serra FM: de curva em curva, de moda em moda."),
     ("AQUI É O SEU ARLINDO, COM O CAFEZINHO DO LADO E O PÉ NA SERRA. BOM DEMAIS DA CONTA TER VOCÊ AQUI.",
      "Aqui é o seu Arlindo, com o cafezinho do lado e o pé na serra. Bom demais da conta ter você aqui."),
     ("SERRA FM 98,7. SE CHIAR NA DESCIDA, ESPERA O MORRO: A GENTE VOLTA LÁ EM CIMA.",
      "Serra FM, noventa e oito, sete. Se chiar na descida, espera o morro: a gente volta lá em cima."),
     ("DICA DO SEU ARLINDO: NA DESCIDA, MARCHA REDUZIDA E FÉ NO FREIO MOTOR.", "Dica do seu Arlindo: na descida, marcha reduzida e fé no freio motor."),
     ("CAUSO DO DIA: O COMPADRE TONHO JURA QUE VIU UMA VACA DANDO SETA NA CURVA DO SAPO. A GENTE ACREDITA, TONHO.",
      "Causo do dia: o compadre Tonho jura que viu uma vaca dando seta na curva do Sapo. A gente acredita, Tonho."),
     ("CAUSO DO DIA: DIZEM QUE NA SERRA TEM UM ORELHÃO QUE SÓ TOCA EM DIA DE NEBLINA. QUEM ATENDE OUVE A SERRA FM.",
      "Causo do dia: dizem que na serra tem um orelhão que só toca em dia de neblina. Quem atende... ouve a Serra FM."),
     ("O SEU ARLINDO PERGUNTA: QUEM AÍ JÁ PAROU NA BEIRA DA ESTRADA SÓ PRA OLHAR O VALE? PARE MAIS. O VALE AGRADECE.",
      "O seu Arlindo pergunta: quem aí já parou na beira da estrada só pra olhar o vale? Pare mais. O vale agradece."),
     ("SERRA FM INFORMA: A QUERMESSE DA CAPELA DE SÃO BENEDITO É SÁBADO. TEM BINGO, QUENTÃO E O LEILÃO DE UM FRANGO ASSADO.",
      "Serra FM informa: a quermesse da capela de São Benedito é sábado. Tem bingo, quentão e o leilão de um frango assado."),
     ("CURIOSIDADE DA SERRA: ARAUCÁRIA LEVA UNS VINTE ANOS PRA DAR PINHÃO. PACIÊNCIA É COM ELA MESMA.",
      "Curiosidade da serra: araucária leva uns vinte anos pra dar pinhão. Paciência é com ela mesma.")],
    [("LITORAL FM 102,3: O SOM QUE TEM CHEIRO DE MARESIA!", "Litoral FM, cento e dois, três: o som que tem cheiro de maresia!"),
     ("LITORAL FM: ABRE A JANELA E AUMENTA O VOLUME!", "Litoral FM: abre a janela e aumenta o volume!"),
     ("TÁ NA LITORAL, TÁ DE CHINELO. 102,3!", "Tá na Litoral, tá de chinelo. Cento e dois, três!"),
     ("ALÔ, GALERA DA ESTRADA! AQUI É A DJ CAIÇARA, DIRETO DO ESTÚDIO PÉ NA AREIA.",
      "Alô, galera da estrada! Aqui é a dijêi Caiçara, direto do estúdio Pé na Areia."),
     ("BOLETIM DAS ONDAS: MAR DE ALMÔNDEGA NO CANTO ESQUERDO. PERFEITO PRA NINGUÉM.", "Boletim das ondas: mar de almôndega no canto esquerdo. Perfeito pra ninguém."),
     ("PROMOÇÃO LITORAL FM: O DÉCIMO OUVINTE QUE BUZINAR AGORA... NÃO GANHA NADA, MAS FICA FELIZ. BIBI!",
      "Promoção Litoral FM: o décimo ouvinte que buzinar agora... não ganha nada, mas fica feliz. Bi-bi!"),
     ("A DJ CAIÇARA AVISA: PROTETOR SOLAR NO NARIZ E COTOVELO PRA DENTRO, QUE O VIZINHO DE FAIXA AGRADECE.",
      "A dijêi Caiçara avisa: protetor solar no nariz e cotovelo pra dentro, que o vizinho de faixa agradece."),
     ("LITORAL FM 102,3: A ÚNICA RÁDIO COM AREIA DENTRO DO MICROFONE.", "Litoral FM, cento e dois, três: a única rádio com areia dentro do microfone."),
     ("CURIOSIDADE DA LITORAL: O CARANGUEJO ANDA DE LADO E NUNCA LEVOU MULTA. FICA A REFLEXÃO.",
      "Curiosidade da Litoral: o caranguejo anda de lado e nunca levou multa. Fica a reflexão."),
     ("PERGUNTA DO DIA DA DJ CAIÇARA: BISCOITO OU BOLACHA? MANDE SUA RESPOSTA POR POMBO-CORREIO. A GENTE NÃO VAI LER.",
      "Pergunta do dia da dijêi Caiçara: biscoito ou bolacha? Mande sua resposta por pombo-correio. A gente não vai ler.")],
    [("NOITE AM 1040: A COMPANHIA DE QUEM NÃO DORME.", "Noite á-éme, mil e quarenta: a companhia de quem não dorme."),
     ("NOITE AM, DE CORAÇÃO PARA CORAÇÃO, DE FAROL PARA FAROL.", "Noite á-éme... de coração para coração, de farol para farol."),
     ("AM 1040: O CHIADO É CHARME.", "Á-éme mil e quarenta: o chiado é charme."),
     ("BOA NOITE, MOTORISTA. AQUI É O VALDO, VOZ DE VELUDO, SEGURANDO A MADRUGADA COM VOCÊ.",
      "Boa noite, motorista. Aqui é o Valdo, voz de veludo, segurando a madrugada com você."),
     ("PRA QUEM TÁ NA BOLEIA: MANTÉM O CAFÉ QUENTE E O CORAÇÃO MAIS AINDA.", "Pra quem tá na boleia: mantém o café quente, e o coração mais ainda."),
     ("CORREIO SENTIMENTAL: ELA DISSE QUE VOLTA. ELE DISSE QUE ESPERA. O RÁDIO DIZ: TOCA MAIS UMA.",
      "Correio sentimental: ela disse que volta. Ele disse que espera. O rádio diz: toca mais uma."),
     ("LIGAÇÃO NO AR: ALÔ, VALDO? É O BIGODE, DA CARRETA AZUL. SÓ QUERIA DIZER QUE A LUA TÁ BONITA AQUI NO KM 200. VALEU, BIGODE.",
      "Ligação no ar: alô, Valdo? É o Bigode, da carreta azul. Só queria dizer que a lua tá bonita aqui no quilômetro duzentos. Valeu, Bigode."),
     ("O VALDO EXPLICA: O AM VIAJA MAIS LONGE DE NOITE, QUICANDO NO CÉU. É POR ISSO QUE A GENTE PEGA MELHOR NO ESCURO.",
      "O Valdo explica: o á-éme viaja mais longe de noite, quicando no céu. É por isso que a gente pega melhor no escuro."),
     ("PENSAMENTO DA MADRUGADA: A ESTRADA É COMPRIDA, MAS A MÚSICA É BOA. E O CAFÉ DO POSTO É FORTE.",
      "Pensamento da madrugada: a estrada é comprida, mas a música é boa. E o café do posto é forte."),
     ("NOITE AM 1040. SE O SOL NASCER E A GENTE SUMIR NO CHIADO, NÃO É ABANDONO: É FÍSICA.",
      "Noite á-éme, mil e quarenta. Se o sol nascer e a gente sumir no chiado, não é abandono: é física.")],
]

# propagandas gerais: cada estação tem as suas (índice % 3), gravadas na voz dela
ADS = [
    ("BORRACHARIA DO TIÃO, 24 HORAS: FUROU O PNEU? O TIÃO ACORDA. FUROU DE MADRUGADA? O TIÃO ACORDA RECLAMANDO.",
     "Borracharia do Tião, vinte e quatro horas: furou o pneu? O Tião acorda. Furou de madrugada? O Tião acorda... reclamando."),
    ("PAMONHA DA DONA ZICA, NO TREVO: DOCE, SALGADA E A DE QUEIJO QUE FAZ CHORAR. TEM CURAU TAMBÉM!",
     "Pamonha da dona Zica, no trevo: doce, salgada e a de queijo que faz chorar. Tem curau também!"),
    ("CHURRASCARIA GAÚCHO SOLITÁRIO, KM 88: RODÍZIO ATÉ O CINTO PEDIR ARREGO. ESTACIONAMENTO PARA CARRETA.",
     "Churrascaria Gaúcho Solitário, quilômetro oitenta e oito: rodízio até o cinto pedir arrego. Estacionamento para carreta."),
    ("AUTOESCOLA DEVAGAR SE VAI AO LONGE: APROVAÇÃO GARANTIDA OU A GENTE TENTA DE NOVO, SEM PRESSA.",
     "Autoescola Devagar Se Vai ao Longe: aprovação garantida, ou a gente tenta de novo, sem pressa."),
    ("COLCHÕES SONO DE PEDRA: VOCÊ DEITA, VOCÊ DORME, VOCÊ PERDE A NOVELA. NA SAÍDA DA CIDADE.",
     "Colchões Sono de Pedra: você deita, você dorme, você perde a novela. Na saída da cidade."),
    ("QUEIJARIA SERRA AZUL: QUEIJO FRESCO, MEIA-CURA E O CURADO QUE O VÔ ESCONDE. PROVE SEM COMPROMISSO.",
     "Queijaria Serra Azul: queijo fresco, meia-cura e o curado que o vô esconde. Prove sem compromisso."),
    ("POSTO TRÊS IRMÃOS: CALIBRAGEM GRÁTIS, CAFÉ COADO NA HORA E O BANHEIRO MAIS LIMPO DA REGIÃO. PALAVRA DO IRMÃO DO MEIO.",
     "Posto Três Irmãos: calibragem grátis, café coado na hora e o banheiro mais limpo da região. Palavra do irmão do meio."),
    ("PASTELARIA KM 12: PASTEL DE CARNE, DE QUEIJO E DE VENTO. O DE VENTO É GRÁTIS.",
     "Pastelaria Quilômetro Doze: pastel de carne, de queijo e de vento. O de vento é grátis."),
    ("FUNILARIA MARTELINHO DO NECO: AMASSOU? O NECO DESAMASSA. NÃO AMASSOU? PASSA PRA TOMAR UM CAFÉ.",
     "Funilaria Martelinho do Neco: amassou? O Neco desamassa. Não amassou? Passa pra tomar um café."),
    ("MERCEARIA DO TREVO: TEM DE TUDO. O QUE NÃO TEM, O SEU LAÉRCIO ARRUMA ATÉ QUINTA.",
     "Mercearia do Trevo: tem de tudo. O que não tem, o seu Laércio arruma até quinta."),
    ("RESTAURANTE COMIDA DE MÃE, KM 140: PRATO FEITO COM OVO FRITO EM CIMA. REPETECO LIBERADO.",
     "Restaurante Comida de Mãe, quilômetro cento e quarenta: prato feito com ovo frito em cima. Repeteco liberado."),
    ("LAVA-RÁPIDO BRILHO DA SERRA: LAVA, ENCERA E AINDA DÁ CONSELHO AMOROSO. CHOVEU DEPOIS? LAVA DE NOVO PELA METADE.",
     "Lava-rápido Brilho da Serra: lava, encera e ainda dá conselho amoroso. Choveu depois? Lava de novo pela metade."),
    ("LOJA TERÇO E DADO: TERÇO, DADO DE PELÚCIA E CACHORRINHO QUE BALANÇA A CABEÇA. ENFEITE SEU RETROVISOR!",
     "Loja Terço e Dado: terço, dado de pelúcia e cachorrinho que balança a cabeça. Enfeite seu retrovisor!"),
    ("CALDO DE CANA DO ZÉ GARAPA: COM LIMÃO, COM ABACAXI OU PURO. A GARAPA MAIS GELADA DESDE 1971.",
     "Caldo de cana do Zé Garapa: com limão, com abacaxi ou puro. A garapa mais gelada desde mil novecentos e setenta e um."),
    ("OFICINA DO SEU DITO: CONSERTA CARRO ANTIGO, CARRO NOVO E CORAÇÃO PARTIDO. ESTE ÚLTIMO SÓ NA CONVERSA.",
     "Oficina do seu Dito: conserta carro antigo, carro novo e coração partido. Este último, só na conversa."),
    ("FEIRA DO ROLO, DOMINGO NO PÁTIO DA ESTAÇÃO: TROQUE SEU RÁDIO VELHO POR UMA BICICLETA. OU O CONTRÁRIO.",
     "Feira do Rolo, domingo no pátio da estação: troque seu rádio velho por uma bicicleta. Ou o contrário."),
    ("BARRACA DA TIA NICE: BOLO DE ROLO, DOCE DE LEITE E GOIABADA CASCÃO. ACEITA CARTÃO, FIADO NÃO.",
     "Barraca da tia Nice: bolo de rolo, doce de leite e goiabada cascão. Aceita cartão... fiado, não."),
    ("HOTEL FAZENDA RECANTO DAS MARITACAS: PISCINA, TIROLESA E CAFÉ DA MANHÃ COM QUARENTA TIPOS DE BOLO.",
     "Hotel Fazenda Recanto das Maritacas: piscina, tirolesa e café da manhã com quarenta tipos de bolo."),
    ("PEIXARIA MAR À VISTA, A 300 KM DO MAR: PEIXE FRESCO, PALAVRA DE PESCADOR.",
     "Peixaria Mar à Vista, a trezentos quilômetros do mar: peixe fresco, palavra de pescador."),
    ("MATERIAL DE CONSTRUÇÃO TIJOLINHO: CIMENTO, AREIA E UM BALCONISTA QUE SABE O NOME DE TODO MUNDO.",
     "Material de construção Tijolinho: cimento, areia e um balconista que sabe o nome de todo mundo."),
    ("SALÃO DA LENI: CORTE, ESCOVA E AS NOTÍCIAS DA CIDADE INTEIRA, TUDO NUM PREÇO SÓ.",
     "Salão da Leni: corte, escova e as notícias da cidade inteira, tudo num preço só."),
]
ADS_ST = [
    [("LEILÃO DE GADO NO PARQUE DE EXPOSIÇÕES, SÁBADO: VENHA PELA VACA, FIQUE PELA PAMONHA.",
      "Leilão de gado no Parque de Exposições, sábado: venha pela vaca, fique pela pamonha."),
     ("CASA DA LÃ: BLUSA DE TRICÔ PRA SUBIR A SERRA SEM BATER QUEIXO.", "Casa da Lã: blusa de tricô pra subir a serra sem bater queixo."),
     ("MEL DO SEU BENÊ: DIRETO DA ABELHA PRO SEU PÃO. A ABELHA NÃO COBRA, O BENÊ COBRA POUCO.",
      "Mel do seu Benê: direto da abelha pro seu pão. A abelha não cobra... o Benê cobra pouco.")],
    [("ALUGA-SE GUARDA-SOL E CADEIRA NA PRAIA DO MEIO. O ISOPOR É POR SUA CONTA.", "Aluga-se guarda-sol e cadeira na Praia do Meio. O isopor é por sua conta."),
     ("SORVETERIA PICOLÉ DE COCO: DERRETEU ANTES DE CHEGAR NO CARRO? A GENTE DÁ OUTRO.",
      "Sorveteria Picolé de Coco: derreteu antes de chegar no carro? A gente dá outro!"),
     ("ESCOLA DE SURFE ONDA MANSA: EM TRÊS AULAS VOCÊ FICA DE PÉ. NA AREIA, MAS FICA.",
      "Escola de surfe Onda Mansa: em três aulas você fica de pé. Na areia, mas fica.")],
    [("DISQUE-CAFÉ DO POSTO 24 HORAS: CAFÉ PRETO, PÃO NA CHAPA E UMA CONVERSA PRA ESPANTAR O SONO.",
      "Disque-café do posto, vinte e quatro horas: café preto, pão na chapa e uma conversa pra espantar o sono."),
     ("PADARIA MADRUGADA: O PÃO SAI ÀS QUATRO, O PADEIRO ACORDA ÀS TRÊS, O GALO SÓ DEPOIS.",
      "Padaria Madrugada: o pão sai às quatro, o padeiro acorda às três... o galo, só depois."),
     ("CURSO DE CONSERTO DE RÁDIO POR CORRESPONDÊNCIA: DOZE LIÇÕES E VOCÊ NUNCA MAIS FICA SEM A NOITE AM.",
      "Curso de conserto de rádio por correspondência: doze lições, e você nunca mais fica sem a Noite á-éme.")],
]

# boletins da estrada: as três estações dão, então cada um tem as três vozes
BR = "bê-érre cento e dezesseis"
ROAD_NEWS = {
    "terra": [("BOLETIM DA ESTRADA DO SÍTIO: TERRA BATIDA, ALGUNS BURACOS DE RESPEITO E A VACA MIMOSA NO ACOSTAMENTO. VÁ DEVAGAR.",
               "Boletim da estrada do sítio: terra batida, alguns buracos de respeito e a vaca Mimosa no acostamento. Vá devagar."),
              ("AVISO DA ESTRADA DO SÍTIO: MÃO DUPLA. OLHE BEM ANTES DE PASSAR O TRATOR. ELE NÃO TEM PRESSA, E VOCÊ TAMBÉM NÃO.",
               "Aviso da estrada do sítio: mão dupla. Olhe bem antes de passar o trator. Ele não tem pressa, e você também não."),
              ("QUEM VAI PELA ESTRADA DO SÍTIO: A VENDA TEM CAFÉ FRESQUINHO E QUEIJO DO DIA.",
               "Quem vai pela estrada do sítio: a venda tem café fresquinho e queijo do dia."),
              ("ESTRADA DO SÍTIO: A PORTEIRA DO SEU ZICO TÁ ABERTA DE NOVO. SE VIR UM BEZERRO PASSEANDO, É ELE.",
               "Estrada do sítio: a porteira do seu Zico tá aberta de novo. Se vir um bezerro passeando, é ele.")],
    "br": [("TRÂNSITO NA BR-116: MOVIMENTO BOM, CAMINHÃO NA FAIXA DA DIREITA, APRESSADO NA ESQUERDA. E VOCÊ NO MEIO, CURTINDO.",
            f"Trânsito na {BR}: movimento bom, caminhão na faixa da direita, apressado na esquerda. E você no meio, curtindo."),
           ("AVISO PRA BR-116: TEM TRECHO DE PISTA IRREGULAR. OLHO NA PLACA E MÃO FIRME NO VOLANTE.",
            f"Aviso pra {BR}: tem trecho de pista irregular. Olho na placa e mão firme no volante."),
           ("O POSTO DA BR-116 AVISA: TANQUE NA RESERVA? PASSA NA FAIXA DA DIREITA QUE O FRENTISTA JÁ SABE.",
            f"O posto da {BR} avisa: tanque na reserva? Passa na faixa da direita, que o frentista já sabe."),
           ("BR-116: OS CAMINHONEIROS MANDAM AVISAR QUE A FILA DO PASTEL NO POSTO TÁ ANDANDO RÁPIDO.",
            f"{BR[0].upper() + BR[1:]}: os caminhoneiros mandam avisar que a fila do pastel no posto tá andando rápido.")],
    "expressa": [("RODOVIA EXPRESSA: CONCRETO LISO, QUATRO FAIXAS E UM PAINEL DE LED DIZENDO O ÓBVIO. BOA VIAGEM.",
                  "Rodovia Expressa: concreto liso, quatro faixas e um painel de léd dizendo o óbvio. Boa viagem."),
                 ("NA EXPRESSA O PEDÁGIO TÁ FLUINDO, E O TELEFONE SOS TÁ LÁ PRA QUEM PRECISAR. TOMARA QUE NINGUÉM PRECISE.",
                  "Na Expressa o pedágio tá fluindo, e o telefone ésse-ó-ésse tá lá pra quem precisar. Tomara que ninguém precise."),
                 ("PARADA DA EXPRESSA: CAFÉ E PÃO DE QUEIJO. PARE, ESTIQUE AS PERNAS E VOLTE PRO EMBALO.",
                  "Parada da Expressa: café e pão de queijo. Pare, estique as pernas e volte pro embalo."),
                 ("RODOVIA EXPRESSA INFORMA: O RADAR TÁ LIGADO, MAS O RÁDIO TAMBÉM. FIQUE COM O RÁDIO.",
                  "Rodovia Expressa informa: o radar tá ligado, mas o rádio também. Fique com o rádio.")],
}

# recados de ouvinte gravados: quatro por estação (o letreiro usa o mesmo molde do recado sorteado)
RECADO_FMT = "RECADO DE OUVINTE: ALÔ, %s %s! %s. QUEM MANDA É %s."
RECADOS = [
    [(("DONA CIDA", "DO KM 43", "SEU FILHO CHEGOU BEM E MANDOU UM BEIJO", "SUA COMADRE"),
      "Recado de ouvinte: alô, dona Cida, do quilômetro quarenta e três! Seu filho chegou bem e mandou um beijo. Quem manda é a sua comadre."),
     (("SEU JOÃO DA PORTEIRA AZUL", "DE SANTA RITA DO MORRO", "A GALINHA PINTADINHA VOLTOU SOZINHA PRO GALINHEIRO", "O COMPADRE ZÉ"),
      "Recado de ouvinte: alô, seu João da Porteira Azul, de Santa Rita do Morro! A galinha pintadinha voltou sozinha pro galinheiro. Quem manda é o compadre Zé."),
     (("DONA LURDINHA", "DA VILA DOS IPÊS", "O BOLO DE FUBÁ TÁ NO FORNO, NÃO DEMORA", "A FILHA MAIS VELHA"),
      "Recado de ouvinte: alô, dona Lurdinha, da Vila dos Ipês! O bolo de fubá tá no forno, não demora. Quem manda é a filha mais velha."),
     (("VÔ ARLINDINHO", "DO SÍTIO TRÊS PORTEIRAS", "PARABÉNS PELOS 80 ANOS, E QUE VENHAM MAIS 80", "A TURMA DO TRUCO"),
      "Recado de ouvinte: alô, vô Arlindinho, do Sítio Três Porteiras! Parabéns pelos oitenta anos, e que venham mais oitenta. Quem manda é a turma do truco.")],
    [(("A TURMA DA VAN DA EXCURSÃO", "DO TREVO DE BAIXO", "O TIME DA VILA GANHOU DE 3 A 2, COM GOL DO GOLEIRO", "O PESSOAL DA OFICINA"),
      "Recado de ouvinte: alô, turma da van da excursão, do Trevo de Baixo! O time da vila ganhou de três a dois, com gol do goleiro! Quem manda é o pessoal da oficina."),
     (("DONA FIA", "DE SÃO BENEDITO DAS ÁGUAS", "TIRA A ROUPA DO VARAL QUE VEM CHUVA", "A VIZINHA DA FRENTE"),
      "Recado de ouvinte: alô, dona Fia, de São Benedito das Águas! Tira a roupa do varal, que vem chuva. Quem manda é a vizinha da frente."),
     (("SEU QUINZINHO", "LÁ DO BAIRRO DA PONTE", "O CACHORRO COMEU O CHINELO DE NOVO", "O GENRO"),
      "Recado de ouvinte: alô, seu Quinzinho, lá do Bairro da Ponte! O cachorro comeu o chinelo de novo. Quem manda é o genro."),
     (("A PROFESSORA ROSÂNGELA", "DE PEDRA BRANCA DO SUL", "A JABUTICABEIRA CARREGOU, VEM BUSCAR UM BALDE", "SUA COMADRE"),
      "Recado de ouvinte: alô, professora Rosângela, de Pedra Branca do Sul! A jabuticabeira carregou, vem buscar um balde. Quem manda é a sua comadre.")],
    [(("O CAMINHONEIRO BIGODE", "DO POSTO DO KM 112", "O CARBURADOR FICOU PRONTO, PODE BUSCAR", "O PESSOAL DA OFICINA"),
      "Recado de ouvinte: alô, caminhoneiro Bigode, do posto do quilômetro cento e doze! O carburador ficou pronto, pode buscar. Quem manda é o pessoal da oficina."),
     (("SEU TONHO DO CAMINHÃO BAÚ", "DA CURVA DO SAPO", "A NETINHA NASCEU! TRÊS QUILOS E UM CHORO DE RESPEITO", "A FILHA MAIS VELHA"),
      "Recado de ouvinte: alô, seu Tonho do caminhão baú, da curva do Sapo! A netinha nasceu! Três quilos e um choro de respeito. Quem manda é a filha mais velha."),
     (("TIA DIRCE", "DO KM 43", "A CHAVE TÁ DEBAIXO DO VASO DE SAMAMBAIA", "O GENRO"),
      "Recado de ouvinte: alô, tia Dirce, do quilômetro quarenta e três! A chave tá debaixo do vaso de samambaia. Quem manda é o genro."),
     (("DONA ZEFA", "DA VILA DOS IPÊS", "O GATO SUBIU NO TELHADO E NÃO QUER DESCER, MAS TÁ TUDO BEM", "O COMPADRE ZÉ"),
      "Recado de ouvinte: alô, dona Zefa, da Vila dos Ipês! O gato subiu no telhado e não quer descer... mas tá tudo bem. Quem manda é o compadre Zé.")],
]

# previsão: sol (de dia), noite (céu limpo fora do dia), chuva, variavel
TEMPO = [
    {"sol": ("PREVISÃO DO TEMPO COM O SEU ARLINDO: TEMPO FIRME E CÉU AZUL DE BRIGADEIRO NA SERRA. ESTRADA SECA E POEIRA NA TERRA. TEMPO DE CALDO DE CANA.",
             "Previsão do tempo com o seu Arlindo: tempo firme e céu azul de brigadeiro na serra. Estrada seca, e poeira na terra. Tempo de caldo de cana."),
     "noite": ("PREVISÃO DO TEMPO COM O SEU ARLINDO: CÉU LIMPO E ESTRELADO, COM NEBLINA NOS VALES. DEVAGAR NA NEBLINA, QUE ELA PASSA. TEMPO DE CAFÉ COM BOLO.",
               "Previsão do tempo com o seu Arlindo: céu limpo e estrelado, com neblina nos vales. Devagar na neblina, que ela passa. Tempo de café com bolo."),
     "chuva": ("PREVISÃO DO TEMPO COM O SEU ARLINDO: CHUVA NA SERRA E NO VALE. CAPRICHE NO LIMPADOR, FAROL BAIXO E DISTÂNCIA DO CARRO DA FRENTE. TEMPO DE CAFÉ COM BOLO.",
               "Previsão do tempo com o seu Arlindo: chuva na serra e no vale. Capriche no limpador, farol baixo e distância do carro da frente. Tempo de café com bolo."),
     "variavel": ("PREVISÃO DO TEMPO COM O SEU ARLINDO: TEMPO VARIÁVEL, ABRE E FECHA. PODE VIR UMA PANCADA DE CHUVA, ENTÃO DEIXE O LIMPADOR DE PRONTIDÃO.",
                  "Previsão do tempo com o seu Arlindo: tempo variável, abre e fecha. Pode vir uma pancada de chuva, então deixe o limpador de prontidão.")},
    {"sol": ("PREVISÃO LITORAL FM: SOL ABERTO, CÉU LIMPO E VENTINHO DO MAR. ÓCULOS ESCUROS E COTOVELO PRA DENTRO. DIA DE PRAIA ATÉ PRA QUEM TÁ NA ESTRADA!",
             "Previsão Litoral FM: sol aberto, céu limpo e ventinho do mar. Óculos escuros e cotovelo pra dentro. Dia de praia até pra quem tá na estrada!"),
     "noite": ("PREVISÃO LITORAL FM: CÉU ESTRELADO E BRISA FRESCA DO MAR. FAROL LIGADO E OLHO NO ACOSTAMENTO. O LUAU TÁ GARANTIDO!",
               "Previsão Litoral FM: céu estrelado e brisa fresca do mar. Farol ligado e olho no acostamento. O luau tá garantido!"),
     "chuva": ("PREVISÃO LITORAL FM: CHUVA NA PISTA E NA AREIA. CUIDADO COM AS POÇAS, QUE O CARRO BOIA. NA PRAIA? GUARDA-CHUVA VIRA GUARDA-SOL.",
               "Previsão Litoral FM: chuva na pista e na areia. Cuidado com as poças, que o carro boia. Na praia? Guarda-chuva vira guarda-sol."),
     "variavel": ("PREVISÃO LITORAL FM: SOL E CHUVA DISPUTANDO O CÉU. PANCADA RÁPIDA DE VERÃO E DEPOIS ABRE DE NOVO. CHINELO E GUARDA-CHUVA NO BANCO DE TRÁS!",
                  "Previsão Litoral FM: sol e chuva disputando o céu. Pancada rápida de verão, e depois abre de novo. Chinelo e guarda-chuva no banco de trás!")},
    {"sol": ("PREVISÃO PRA QUEM VIAJA NA NOITE AM: SOL ABERTO E TEMPO FIRME. QUEBRA-SOL ABAIXADO. DE DIA O AM CHIA, MAS A GENTE NÃO DESLIGA.",
             "Previsão pra quem viaja na Noite á-éme: sol aberto e tempo firme. Quebra-sol abaixado. De dia o á-éme chia... mas a gente não desliga."),
     "noite": ("PREVISÃO PRA QUEM VIAJA NA NOITE AM: CÉU LIMPO E ESTRELADO. FAROL LIGADO E OLHO NO ACOSTAMENTO. CÉU ASSIM O AM VAI LONGE.",
               "Previsão pra quem viaja na Noite á-éme: céu limpo e estrelado. Farol ligado e olho no acostamento. Céu assim, o á-éme vai longe."),
     "chuva": ("PREVISÃO PRA QUEM VIAJA NA NOITE AM: CHUVA NA ESTRADA. FAROL BAIXO E DISTÂNCIA DO CARRO DA FRENTE. COM CHUVA O AM CHIA MAIS, MAS NÃO DESISTE.",
               "Previsão pra quem viaja na Noite á-éme: chuva na estrada. Farol baixo e distância do carro da frente. Com chuva o á-éme chia mais... mas não desiste."),
     "variavel": ("PREVISÃO PRA QUEM VIAJA NA NOITE AM: TEMPO VARIÁVEL, NUVEM CHEGANDO E INDO EMBORA. SE APERTAR A CHUVA, DEVAGAR. O VALDO FICA AQUI COM VOCÊ.",
                  "Previsão pra quem viaja na Noite á-éme: tempo variável, nuvem chegando e indo embora. Se apertar a chuva, devagar. O Valdo fica aqui com você.")},
]

# hora certa genérica: a fala não diz a hora (os bipes dizem); o letreiro mostra o relógio no lugar do %s
HORA_SHORT = ["SERRA FM", "LITORAL FM", "NOITE AM"]
HORA_FALA = ["Serra FM", "Litoral FM", "Noite á-éme"]
HORA_TAIL = {   # madrugada, manha, tarde, noite: os mesmos fechos do hora_certa() de radio.gd
    "madrugada": [("QUEM TÁ ACORDADO A ESSA HORA, UM ABRAÇO.", "Quem tá acordado a essa hora, um abraço."),
                  ("A CIDADE DORME, A ESTRADA NÃO.", "A cidade dorme... a estrada, não."),
                  ("SÓ NÓS, OS CAMINHÕES E A LUA.", "Só nós, os caminhões e a lua.")],
    "manha": [("BOM DIA, QUE O CAFÉ JÁ PASSOU.", "Bom dia, que o café já passou."),
              ("BOM DIA, GALERA! O MAR JÁ ACORDOU.", "Bom dia, galera! O mar já acordou."),
              ("O SOL TÁ CHEGANDO E O AM TÁ INDO DORMIR.", "O sol tá chegando, e o á-éme tá indo dormir.")],
    "tarde": [("BOA TARDE, QUE O PÃO DE QUEIJO TÁ SAINDO.", "Boa tarde, que o pão de queijo tá saindo."),
              ("BOA TARDE! HORA DO PICOLÉ.", "Boa tarde! Hora do picolé."),
              ("A NOITE AM TÁ AQUI, MESMO DE DIA, CHIANDO COM CARINHO.", "A Noite á-éme tá aqui, mesmo de dia, chiando com carinho.")],
    "noite": [("BOA NOITE, FAROL BAIXO E CORAÇÃO TRANQUILO.", "Boa noite. Farol baixo e coração tranquilo."),
              ("BOA NOITE! O LUAU TÁ COMEÇANDO.", "Boa noite! O luau tá começando."),
              ("BOA NOITE, MOTORISTA. AGORA O AM PEGA BONITO.", "Boa noite, motorista. Agora o á-éme pega bonito.")],
}

# chamadas das músicas: duas por música, nos moldes de DJ_INTRO da estação
TRACKS = [("radio0", "TRIO ASFALTO", "CHUVA NA SERRA", 0), ("radio_serra_1", "DONA NEBLINA", "CAFÉ DE BEIRA DE ESTRADA", 0),
          ("radio_serra_2", "OS PRIMOS DA CURVA", "MODA DO PNEU CARECA", 0), ("radio_serra_3", "TRIO ASFALTO", "FAROL BAIXO", 0),
          ("radio1", "OS VAGALUMES", "JANELA ABERTA", 1), ("radio_litoral_1", "ZÉ DA BALSA", "SAMBA DO ACOSTAMENTO", 1),
          ("radio_litoral_2", "BEL MARESIA", "BOSSA DO PEDÁGIO", 1), ("radio_litoral_3", "OS VAGALUMES", "MARESIA NO PAINEL", 1),
          ("radio2", "BANDA NEON", "KM 43", 2), ("radio_noite_1", "CONJUNTO MADRUGADA", "BOLERO DO FAROL ALTO", 2),
          ("radio_noite_2", "BANDA NEON", "LUZ DE FREIO", 2), ("radio_noite_3", "SINTONIA FINA", "ÚLTIMO PEDÁGIO", 2),
          ("musica/serra_me_leva_pra_casa", "IRMÃOS DO PINHEIRAL", "SERRA ME LEVA PRA CASA", 0),
          ("musica/vou_de_brisa", "LUA DE MARÉ", "VOU DE BRISA", 1), ("musica/volta_pra_mim", "ROBSON ESTRELA", "VOLTA PRA MIM", 2)]
DJ_INTRO = [
    [("E AGORA, PRA ACOMPANHAR A SUBIDA: %s, COM \"%s\".", "E agora, pra acompanhar a subida: {a}, com {t}."),
     ("PEDIDO DO PESSOAL DA VENDA: %s, \"%s\".", "Pedido do pessoal da venda: {a}... {t}."),
     ("UMA MODA BOA PRA ESTRADA: %s E \"%s\".", "Uma moda boa pra estrada: {a}, e {t}.")],
    [("SEGURA ESSA, GALERA: %s, \"%s\"!", "Segura essa, galera: {a}, {t}!"),
     ("SOBE O SOM: %s COM \"%s\"!", "Sobe o som: {a}, com {t}!"),
     ("DIRETO DA AREIA PRO SEU PAINEL: %s, \"%s\".", "Direto da areia pro seu painel: {a}... {t}.")],
    [("PRA QUEM TÁ ACORDADO: %s, \"%s\". DEDICADA A VOCÊ, MOTORISTA.", "Pra quem tá acordado: {a}... {t}. Dedicada a você, motorista."),
     ("APAGA A LUZ DO PAINEL E OUVE: %s, \"%s\".", "Apaga a luz do painel e ouve: {a}... {t}."),
     ("DO FUNDO DO BAÚ DA MADRUGADA: %s, \"%s\".", "Do fundo do baú da madrugada: {a}... {t}.")],
]
FALADO = {"KM 43": "Quilômetro Quarenta e Três"}

def nome(s):
    if s in FALADO:
        return FALADO[s]
    small = {"DE", "DA", "DO", "E", "NO", "NA", "OS"}
    w = [x.lower() if (i > 0 and x in small) else x.capitalize() for i, x in enumerate(s.split())]
    return " ".join(w)


# ---------------------------------------------------------------- the list of lines
def lines():
    L = []   # dict: id, st, kind, tela, fala, + extra
    for si in range(3):
        for k, (t, f) in enumerate(SLOGANS[si]):
            L.append({"id": f"{EST[si]}_slogan_{k + 1:02d}", "st": si, "kind": "slogan", "tela": t, "fala": f})
        for k, (t, f) in enumerate(ADS):
            if k % 3 == si:
                L.append({"id": f"{EST[si]}_anuncio_{k + 1:02d}", "st": si, "kind": "ad", "tela": t, "fala": f})
        for k, (t, f) in enumerate(ADS_ST[si]):
            L.append({"id": f"{EST[si]}_anuncio_local_{k + 1}", "st": si, "kind": "ad", "tela": t, "fala": f})
        for road, l in ROAD_NEWS.items():
            for k, (t, f) in enumerate(l):
                L.append({"id": f"{EST[si]}_estrada_{road}_{k + 1}", "st": si, "kind": "estrada", "road": road, "tela": t, "fala": f})
        for k, (parts, f) in enumerate(RECADOS[si]):
            L.append({"id": f"{EST[si]}_recado_{k + 1}", "st": si, "kind": "recado", "tela": RECADO_FMT % parts, "fala": f})
        for cond, (t, f) in TEMPO[si].items():
            L.append({"id": f"{EST[si]}_tempo_{cond}", "st": si, "kind": "tempo", "cond": cond, "tela": t, "fala": f})
        for per, tails in HORA_TAIL.items():
            t, f = tails[si]
            L.append({"id": f"{EST[si]}_hora_{per}", "st": si, "kind": "hora", "period": per,
                      "tela": f"HORA CERTA {HORA_SHORT[si]}: %s. {t}", "fala": f"Hora certa, {HORA_FALA[si]}. {f}"})
        mine = [i for i, tr in enumerate(TRACKS) if tr[3] == si]
        for k, ti in enumerate(mine):
            _, art, tit, _ = TRACKS[ti]
            for j in (k % 3, (k + 1) % 3):
                t, f = DJ_INTRO[si][j]
                L.append({"id": f"{EST[si]}_chamada_{TRACKS[ti][0].replace('/', '_')}_{j + 1}", "st": si, "kind": "intro", "song": ti,
                          "tela": t % (art, tit), "fala": f.format(a=nome(art), t=nome(tit))})
    return L


def dur(path):
    return float(subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path]).decode().strip())


def gd_str(s):
    return json.dumps(s, ensure_ascii=False)


def main():
    dry = "--dry" in sys.argv
    L = lines()
    os.makedirs(OUT, exist_ok=True)
    os.makedirs(BRUTO, exist_ok=True)
    todo = [x for x in L if not os.path.exists(os.path.join(OUT, x["id"] + ".ogg"))]
    print(f"{len(L)} falas, {sum(len(x['fala']) for x in L)} caracteres; faltam {len(todo)} ({sum(len(x['fala']) for x in todo)} caracteres)")
    if dry:
        return
    for x in todo:
        raw = os.path.join(BRUTO, x["id"] + ".mp3")
        if not os.path.exists(raw):
            v = VOZES[x["st"]]
            subprocess.run([sys.executable, os.path.join(ROOT, "tools/ai/eleven.py"), "tts", raw, v["id"], x["fala"]] + v["args"], check=True)
        # mono, small silence trimmed at the ends, loudness evened out (radio voice, a bit hot), ogg for Godot
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", raw, "-af",
                        "silenceremove=start_periods=1:start_threshold=-50dB,areverse,silenceremove=start_periods=1:start_threshold=-50dB,areverse,"
                        "loudnorm=I=-16:TP=-1.5:LRA=7,apad=pad_dur=0.15", "-ac", "1", "-ar", "44100", "-c:a", "libvorbis", "-q:a", "4",
                        os.path.join(OUT, x["id"] + ".ogg")], check=True)
        print("ok", x["id"])
    # the index, as GDScript
    out = ["# Gerado por tools/ai/vozes_radio.py: não edite à mão. Locução do rádio (ElevenLabs).",
           "# Cada fala: arquivo em assets/audio/voz/, estação (0 serra, 1 litoral, 2 noite), tipo, texto do letreiro e duração.",
           "# hora: o %s do letreiro é o relógio. tempo: cond sol|noite|chuva|variavel. intro: song = índice em TRACKS.",
           "const VOZES := ["]
    for x in L:
        f = os.path.join(OUT, x["id"] + ".ogg")
        if not os.path.exists(f):
            continue
        extra = "".join(f', "{k}": {gd_str(x[k])}' for k in ("road", "cond", "period", "song") if k in x)
        out.append(f'\t{{"file": "{x["id"]}", "st": {x["st"]}, "kind": "{x["kind"]}", "dur": {dur(f):.2f}{extra},\n\t\t"tela": {gd_str(x["tela"])}}},')
    out.append("]")
    open(INDEX, "w").write("\n".join(out) + "\n")
    print("índice:", INDEX)


if __name__ == "__main__":
    main()
