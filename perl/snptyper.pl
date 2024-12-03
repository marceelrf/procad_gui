#!/usr/bin/perl
use strict;
use warnings;
use WWW::Mechanize;
use File::Path qw(make_path);
use File::Basename;
use File::Copy;

# Variáveis principais
my $diretorio = "/home/lab/Desktop/a/microhaplotipos/result_snp_mapper";
my $vcf_base = "/home/lab/Downloads/VCFs/1kGP_high_coverage_Illumina";
my $name_snps_dir = "$diretorio/name_snps";
my $out_dir_fasta = "$diretorio/fasta_snps";
my $bed_dir = "$diretorio/bed_files";
my $output_diretorio_structure = "$diretorio/resultados_structure";
my $structure_db_dir = "$diretorio/structure_db";
my $mainparams_base = "$diretorio/structure_db/mainparams_base";
my $extraparams_file = "$diretorio/structure_db/extraparams_base";
my $structure_bin = "/shared/apps/structure/structure_run/structure_linux";
my $parametros_populacionais = "$diretorio/structure_db/id_pop_structure.txt";
my $bcftools = "bcftools";

# Mapear bases para números
my %base_map = (
    'A' => 1,
    'C' => 2,
    'G' => 3,
    'T' => 4,
    '-' => -9
);

# Função para criar diretórios
sub verificar_e_criar_diretorio {
    my ($path) = @_;
    unless (-d $path) {
        print "Criando diretório: $path\n";
        make_path($path) or die "Erro ao criar o diretório $path: $!\n";
    }
}

# Preparar diretórios principais
verificar_e_criar_diretorio($out_dir_fasta);
verificar_e_criar_diretorio($bed_dir);
verificar_e_criar_diretorio($output_diretorio_structure);

# Ler parâmetros populacionais
open my $pop_fh, '<', $parametros_populacionais or die "Não foi possível abrir $parametros_populacionais: $!\n";
my %pop_data;
while (<$pop_fh>) {
    chomp;
    my ($sample, @params) = split;
    $pop_data{$sample} = \@params;
}
close $pop_fh;

# Processar cada arquivo de SNPs
opendir(my $dir, $name_snps_dir) or die "Não foi possível abrir o diretório: $name_snps_dir\n";
my @arquivos_txt = grep { /\.txt$/ } readdir($dir);
closedir($dir);

foreach my $arquivo_snps (@arquivos_txt) {
    my $caminho_snps = "$name_snps_dir/$arquivo_snps";
    my ($base_name) = fileparse($arquivo_snps, qr/\.[^.]*/);
    my $file_bed = "$bed_dir/bed_file_$base_name.txt";
    my $output_dir = "$out_dir_fasta/$base_name";

    verificar_e_criar_diretorio($output_dir);

    print "Processando SNPs de $arquivo_snps...\n";
    my $mech = WWW::Mechanize->new();
    open my $snp_fh, '<', $caminho_snps or die "Não foi possível abrir $caminho_snps: $!\n";
    open my $out_bed, '>', $file_bed or die "Não foi possível criar $file_bed: $!\n";

    my %positions_by_chromosome;
    while (my $snp = <$snp_fh>) {
        chomp $snp;
        print "Buscando $snp no NCBI...\n";
        $mech->get("https://ncbi.nlm.nih.gov/snp/?term=$snp");
        if ($mech->success() && $mech->content() =~ /(\d+):(\d+)\s\((GRCh38)\)/) {
            my ($chromosome, $position) = ($1, $2);
            print $out_bed "chr$chromosome\t$position\t$position\n";
            push @{$positions_by_chromosome{$chromosome}}, $position;
        } else {
            print "SNP $snp não encontrado.\n";
        }
    }
    close $snp_fh;
    close $out_bed;

    # Filtrar VCFs e gerar FASTA
    for my $cross (1..22) {
        my $tag = "chr$cross";
        my $vcfgz = "$vcf_base.$tag.filtered.SNV_INDEL_SV_phased_panel.norm.vcf.gz";
        my $output_vcf = "$output_dir/$tag.snps.vcf";
        my $reference = "/shared/genomes/hg38/chr/$cross.fasta";

        next unless exists $positions_by_chromosome{$cross} && -e $vcfgz;

        my $filter_command = "$bcftools view -R $file_bed $vcfgz -o $output_vcf -Ov";
        system($filter_command) == 0 or die "Erro no comando: $filter_command\n";

        foreach my $snp_position (@{$positions_by_chromosome{$cross}}) {
            my $fasta_path = "$output_dir/$tag.$snp_position.fasta";
            my $fasta_command = "vcfx fasta input=$output_vcf start=$snp_position end=$snp_position output=$fasta_path reference=$reference";
            system($fasta_command) == 0 or die "Erro no comando: $fasta_command\n";
        }
    }

    # Gerar entrada para STRUCTURE
    my $output_structure = "$structure_db_dir/input_${base_name}.txt";
    my $output_mainparams = "$structure_db_dir/mainparams_${base_name}.txt";
    my $output_structure_run = "$output_diretorio_structure/output_${base_name}.txt";
    open my $out_structure, '>', $output_structure or die "Erro ao criar $output_structure: $!\n";

    my %final_data;
    foreach my $sample (keys %pop_data) {
        $final_data{$sample} = [ @{$pop_data{$sample}} ];
    }

    opendir(my $fasta_dir, $output_dir) or die "Erro ao abrir $output_dir: $!\n";
    my @fasta_files = grep { /\.fasta$/ } readdir($fasta_dir);
    closedir($fasta_dir);

    my $num_fastas = scalar @fasta_files;
    foreach my $fasta_file (@fasta_files) {
        my $fasta_path = "$output_dir/$fasta_file";
        open my $fasta_fh, '<', $fasta_path or die "Erro ao abrir $fasta_path: $!\n";

        my %genotypes;
        while (<$fasta_fh>) {
            chomp;
            if (/^>(\w+)_h(\d)$/) {
                my ($sample, $haplotype) = ($1, $2);
                my $sequence = <$fasta_fh>;
                chomp $sequence;
                my $value = $base_map{$sequence} // -9;
                $genotypes{$sample}[$haplotype - 1] = $value;
            }
        }
        close $fasta_fh;

        foreach my $sample (keys %pop_data) {
            my @values = $genotypes{$sample} ? @{$genotypes{$sample}} : (-9, -9);
            push @{$final_data{$sample}}, @values;
        }
    }

    foreach my $sample (sort keys %final_data) {
        print $out_structure join("\t", $sample, @{$final_data{$sample}}), "\n";
    }
    close $out_structure;

    copy($mainparams_base, $output_mainparams) or die "Erro ao copiar $mainparams_base: $!\n";
    open my $mainparams_fh, '+<', $output_mainparams or die "Erro ao editar $output_mainparams: $!\n";
    my @lines = <$mainparams_fh>;
    seek($mainparams_fh, 0, 0);
    foreach my $line (@lines) {
        if ($line =~ /^#define NUMLOCI\s+\d+/) {
            $line = "#define NUMLOCI $num_fastas\n";
        }
        print $mainparams_fh $line;
    }
    close $mainparams_fh;

    my $structure_command = "$structure_bin -i $output_structure -m $output_mainparams -e $extraparams_file -o $output_structure_run";
    system($structure_command) == 0 or warn "Erro ao executar STRUCTURE para $base_name.\n";
    print "Processamento completo para $arquivo_snps.\n";
}

