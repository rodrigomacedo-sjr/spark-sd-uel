# Relatório LaTeX

Esta pasta contém a versão em LaTeX e PDF do relatório técnico do trabalho.

## Arquivos principais

- `relatorio.pdf`: PDF já compilado localmente. Este é o arquivo final para abrir, enviar ou imprimir.
- `main.pdf`: mesmo PDF gerado pelo LaTeX com o nome padrão do arquivo `main.tex`.
- `main.tex`: código-fonte do relatório em LaTeX. Este é o arquivo que deve ser editado no Overleaf.
- `figures/`: imagens usadas no relatório.
- `README.md`: este guia.

## Arquivos gerados pelo LaTeX

Estes arquivos aparecem quando o LaTeX compila o projeto. Eles não precisam ser editados:

- `main.aux`
- `main.log`
- `main.out`
- `main.toc`

No Overleaf, esses arquivos podem ser ignorados. Se eles não forem enviados, o Overleaf recria tudo automaticamente.

## Como usar no Overleaf

1. Crie um projeto em branco.
2. Envie `main.tex`.
3. Envie a pasta `figures/` inteira.
4. Compile com `pdfLaTeX`.

O Overleaf vai gerar o PDF automaticamente. O nome local `relatorio.pdf` existe só para facilitar encontrar o PDF já compilado nesta máquina.

## Pacotes usados

O relatório usa apenas pacotes comuns do Overleaf:

- `babel`
- `geometry`
- `graphicx`
- `booktabs`
- `float`
- `hyperref`
- `xcolor`
- `listings`
- `caption`
- `array`
