
<!-- README.md is generated from README.Rmd. Please edit that file -->

# PROCAD-GUI

<!-- badges: start -->
<!-- badges: end -->

The goal of `PROCAD-GUI` is to …

## Análises

- Ancestralidade;
- Predição de idade;
- Predição de cor dos olhos;
- Predição da cor da pele;

## Tipos de input?

- `fastq`;
- `bam`;

inputs devem ser realizados com
[`shinyFiles`](https://github.com/thomasp85/shinyFiles);

## Tipos de output?

- relatório em pdf?

## Dependencias?

- `BWA`para short-reads;
- `minimap2` para long-reads;
- `samtools`;
- `bcftools`;
- `tabix`;
- `modkit`;
- `structure`;
- `quarto`;

# Etapa de desenvolvimento

- `/Teste_Shiny` contém PoC de funcionalidades que incluiremos na versão
  final;
- `/Cpp` contém funções em C++ para serem chamadas via `Rcpp`;
- `/perl` contém scripts em perl para serem utilizados;
