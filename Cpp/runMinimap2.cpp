#include <Rcpp.h>
#include <iostream>
#include <string>
#include <cstdlib> // Para usar system()

// [[Rcpp::export]]
void runMinimap2(const std::string& input, const std::string& reference, 
                 int threads_num, const std::string& output) {
  // Construção do comando
  std::string sample = input.substr(input.find_last_of("/\\") + 1); // Extrai nome do arquivo como SAMPLE
  sample = sample.substr(0, sample.find_first_of('.')); // Remove extensão
  std::string command = "minimap2 -ax map-ont " + reference + " " + input +
    " -R \"@RG\\tID:" + sample + "\\tSM:" + sample + "\"" +
    " -t " + std::to_string(threads_num) +
    " > " + output;
  
  // Exibe o comando para depuração
  std::cout << "Executando comando: " << command << std::endl;
  
  // Executa o comando
  int result = system(command.c_str());
  
  // Verifica o resultado
  if (result != 0) {
    std::cerr << "Erro ao executar o minimap2. Código de erro: " << result << std::endl;
  } else {
    std::cout << "Execução concluída com sucesso." << std::endl;
  }
}