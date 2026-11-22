# Dock estilo Mac — o que este notebook aguenta

Pedido: um dock como o do macOS, com ícones que **aumentam ao passar o mouse**, que **se esconde** quando um
app abre em tela cheia e volta ao encostar o mouse embaixo, com o visual **Liquid Glass**
(vidro fosco + efeito de lente que deforma o que está atrás).

Hardware: Celeron N3010 (2 núcleos, 1,04 GHz), Intel HD Graphics (Braswell), 2 GB RAM. O Xfce já roda
com o compositor do xfwm4 ligado.

| Parte do pedido | Dá? | Como | Custo |
|---|---|---|---|
| Ícones que crescem com o mouse (magnificação) | ✅ | **Plank** (`0.11.89`, nos repositórios do Debian 13), opção *Zoom* | ~20–40 MB de RAM; CPU só durante a animação |
| Esconder com app em tela cheia e voltar ao encostar o mouse | ✅ | Plank no modo *Intellihide*/*Window dodge* | desprezível |
| Fundo translúcido com brilho de vidro | ✅ | Tema próprio do Plank (cor com transparência + borda clara + reflexo) | desprezível (o compositor já está ligado) |
| **Vidro fosco de verdade** (desfocar o que está atrás) | ⚠️ | Trocar o compositor do xfwm4 pelo **picom** com blur `dual_kawase` (GLX) | Pesado para esta placa: o desfoque é refeito a cada quadro, inclusive com vídeo atrás. Só testando e medindo |
| **Efeito de lente que deforma as bordas** (Liquid Glass da Apple) | ❌ | Não existe dock no Linux/X11 que faça isso; exigiria shader próprio no compositor | Inviável aqui; mesmo em PC bom seria um projeto à parte |

## Recomendação
**Plank com zoom + intellihide + tema "vidro" translucente.** Entrega 90% do visual e da sensação do dock do
Mac, quase sem custo. O vidro fosco com blur real fica como **teste opcional**: instala, mede CPU com
vídeo tocando e desfaz se pesar. O efeito de lente fica de fora.

O Plank substituiria o painel de baixo do Xfce. O painel de cima (relógio, Wi‑Fi, bateria, menu) continua.
