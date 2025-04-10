# Extrator de Dados de Editais de Concursos Públicos

Este projeto implementa um sistema para extração local de dados estruturados de editais de concursos públicos brasileiros em formato PDF, sem depender de APIs externas.

## Funcionalidades

- Extração de texto com preservação de layout
- Reconhecimento de páginas digitalizadas e processamento OCR
- Identificação automática de seções do edital
- Extração de dados estruturados:
  - Identificação do concurso (número do edital, órgão, banca)
  - Cronograma (datas importantes)
  - Informações de inscrição (período, taxa)
  - Cargos e requisitos
  - Distribuição de vagas
  - Remuneração
  - Conteúdo programático
- Extração e análise de tabelas
- Geração de arquivos estruturados (JSON, CSV, TXT)

## Requisitos

- Python 3.8 ou superior
- Dependências listadas em `requirements.txt`

## Instalação

1. Clone o repositório ou baixe os arquivos
2. Instale as dependências:

```bash
pip install -r requirements.txt
```

3. Para usar OCR, instale o Tesseract OCR:
   - Windows: Baixe o instalador em https://github.com/UB-Mannheim/tesseract/wiki
   - Linux: `sudo apt-get install tesseract-ocr`
   - macOS: `brew install tesseract`

## Uso

### Linha de Comando

```bash
python extrair_edital.py caminho/para/edital.pdf [opções]
```

Opções disponíveis:
- `-o, --output-dir`: Diretório de saída para os arquivos gerados
- `--no-ocr`: Desativa o uso de OCR para páginas digitalizadas
- `--debug`: Ativa o modo de depuração (logs mais detalhados)

### Como Biblioteca

```python
from edital_extractor.processors.pdf_processor import PDFProcessor

# Inicializar o processador
processor = PDFProcessor(
    pdf_path='caminho/para/edital.pdf',
    output_dir='diretorio/saida',
    use_ocr=True
)

# Processar o PDF e extrair dados
extracted_data = processor.process()

# Acessar os dados extraídos
print(extracted_data['identificacao'])
print(extracted_data['cronograma'])
print(extracted_data['cargos'])
```

## Arquivos de Saída

O sistema gera os seguintes arquivos:

- `texto_extraido.txt`: Texto completo extraído do PDF
- `secoes_extraidas.txt`: Texto organizado por seções identificadas
- `dados_extraidos.json`: Dados estruturados em formato JSON
- `tabelas/*.csv`: Tabelas extraídas em formato CSV

## Limitações

- A precisão da extração depende da qualidade e estrutura do PDF
- PDFs digitalizados com baixa qualidade podem ter resultados de OCR imprecisos
- Editais com formatos muito não convencionais podem exigir ajustes nas regras de extração
- A interpretação semântica de exceções no conteúdo programático é limitada

## Contribuições

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou enviar pull requests.

## Licença

Este projeto está licenciado sob a licença MIT.
