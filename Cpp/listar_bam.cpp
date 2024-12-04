#include <Rcpp.h>
#include <filesystem>
#include <vector>
#include <cstdlib>  // Para getenv()
namespace fs = std::filesystem;

// Função auxiliar para expandir "~" para o diretório "home" do usuário
std::string expandHome(const std::string& path) {
  if (path.empty() || path[0] != '~') {
    return path; // Retorna o caminho inalterado se não começa com "~"
  }

  const char* homeDir = std::getenv("HOME");
  if (!homeDir) {
    throw std::runtime_error("Diretório home não encontrado (variável HOME não definida).");
  }

  return std::string(homeDir) + path.substr(1); // Substitui "~" pelo diretório "home"
}

// [[Rcpp::export]]
std::vector<std::string> listarArquivosBAM(const std::string& caminhoPasta) {
  std::vector<std::string> arquivosBAM;

  try {
    // Expande o caminho da pasta
    std::string caminhoExpandido = expandHome(caminhoPasta);

    // Itera sobre os arquivos do diretório
    for (const auto& entry : fs::directory_iterator(caminhoExpandido)) {
      if (entry.is_regular_file() && entry.path().extension() == ".bam") {
        arquivosBAM.push_back(entry.path().string());  // Adiciona o caminho do arquivo à lista
      }
    }
  } catch (const fs::filesystem_error& e) {
    Rcpp::Rcout << "Erro ao acessar o diretório: " << e.what() << std::endl;
  } catch (const std::exception& e) {
    Rcpp::Rcout << "Erro geral: " << e.what() << std::endl;
  }
  
  return arquivosBAM;
}
