#include <Rcpp.h>
#include <string>
#include <cstdlib> // Para usar system()

// [[Rcpp::export]]
void runBWAMem(std::string reference, std::string r1, std::string r2, 
               int threads_num, std::string output) {
  // Construção do comando
  std::string sample = r1.substr(r1.find_last_of("/\\") + 1); // Extrai nome do arquivo R1 como SAMPLE
  sample = sample.substr(0, sample.find_first_of('_')); // Assume que o nome da amostra termina antes de "_"
  std::string command = "bwa mem -t " + std::to_string(threads_num) +
    " -R \"@RG\\tID:" + sample + "\\tSM:" + sample + "\"" +
    " " + reference + " " + r1 + " " + r2 +
    " > " + output;
  
  // Exibe o comando no console do R
  Rcpp::Rcout << "Executando comando: " << command << std::endl;
  
  // Executa o comando
  int result = system(command.c_str());
  
  // Verifica o resultado
  if (result != 0) {
    Rcpp::stop("Erro ao executar o BWA mem. Código de erro: " + std::to_string(result));
  } else {
    Rcpp::Rcout << "Execução concluída com sucesso." << std::endl;
  }
}
