"""
Processador principal de PDFs de editais.
"""

import logging
import os
import json
from ..utils.pdf_loader import PDFLoader
from ..utils.ocr_processor import OCRProcessor
from ..extractors.section_extractor import SectionExtractor
from ..extractors.data_extractor import DataExtractor
from ..extractors.table_extractor import TableExtractor

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class PDFProcessor:
    """Classe principal para processamento de PDFs de editais."""
    
    def __init__(self, pdf_path, output_dir=None, use_ocr=True):
        """
        Inicializa o processador de PDF.
        
        Args:
            pdf_path (str): Caminho para o arquivo PDF.
            output_dir (str): Diretório de saída para arquivos gerados.
            use_ocr (bool): Se True, usa OCR para páginas digitalizadas.
        """
        self.pdf_path = pdf_path
        self.output_dir = output_dir or os.path.dirname(pdf_path)
        self.use_ocr = use_ocr
        
        # Criar diretório de saída se não existir
        if not os.path.exists(self.output_dir):
            os.makedirs(self.output_dir)
        
        # Inicializar componentes
        self.pdf_loader = PDFLoader(pdf_path)
        self.ocr_processor = OCRProcessor() if use_ocr else None
        self.section_extractor = SectionExtractor()
        self.data_extractor = DataExtractor()
        self.table_extractor = TableExtractor(pdf_path)
        
        # Armazenar dados extraídos
        self.document_info = None
        self.extracted_text = {}
        self.extracted_sections = {}
        self.extracted_data = {}
        self.extracted_tables = []
    
    def process(self):
        """
        Processa o PDF completo.
        
        Returns:
            dict: Dados extraídos do edital.
        """
        try:
            # Analisar o documento
            self.document_info = self.pdf_loader.analyze_document()
            logger.info(f"Análise do documento concluída: {self.document_info}")
            
            # Extrair texto de todas as páginas
            self._extract_text_from_all_pages()
            
            # Extrair seções
            self._extract_sections()
            
            # Extrair tabelas
            self._extract_tables()
            
            # Extrair dados estruturados
            self._extract_structured_data()
            
            # Salvar resultados
            self._save_results()
            
            return self.extracted_data
        
        except Exception as e:
            logger.error(f"Erro ao processar o PDF: {e}")
            raise
        finally:
            # Fechar o PDF
            self.pdf_loader.close()
    
    def _extract_text_from_all_pages(self):
        """Extrai texto de todas as páginas do PDF."""
        logger.info("Extraindo texto de todas as páginas...")
        
        for page_num in range(self.pdf_loader.page_count):
            is_scanned = page_num in self.pdf_loader.scanned_pages
            
            if is_scanned and self.use_ocr:
                # Usar OCR para páginas digitalizadas
                logger.info(f"Usando OCR para a página {page_num + 1}...")
                img = self.pdf_loader.get_page_as_image(page_num)
                if img:
                    text = self.ocr_processor.perform_ocr(img)
                    self.extracted_text[page_num] = {
                        'text': text,
                        'method': 'ocr',
                        'blocks': None
                    }
            else:
                # Extrair texto com layout para páginas baseadas em texto
                logger.info(f"Extraindo texto com layout da página {page_num + 1}...")
                page_dict = self.pdf_loader.extract_text_with_layout(page_num)
                
                if page_dict:
                    # Extrair texto plano para referência
                    text = ""
                    for block in page_dict.get('blocks', []):
                        if block.get('type') == 0:  # Bloco de texto
                            for line in block.get('lines', []):
                                for span in line.get('spans', []):
                                    text += span.get('text', '')
                                text += "\n"
                    
                    self.extracted_text[page_num] = {
                        'text': text,
                        'method': 'layout',
                        'blocks': page_dict.get('blocks', [])
                    }
        
        logger.info(f"Texto extraído de {len(self.extracted_text)} páginas.")
    
    def _extract_sections(self):
        """Extrai seções do texto extraído."""
        logger.info("Extraindo seções do documento...")
        
        # Processar páginas com informações de layout
        for page_num, page_info in self.extracted_text.items():
            if page_info['method'] == 'layout' and page_info['blocks']:
                logger.info(f"Extraindo seções da página {page_num + 1}...")
                self.section_extractor.extract_sections_from_blocks(page_info['blocks'], page_num)
        
        # Obter todas as seções identificadas
        self.extracted_sections = self.section_extractor.get_all_sections()
        
        logger.info(f"Seções extraídas: {list(self.extracted_sections.keys())}")
    
    def _extract_tables(self):
        """Extrai tabelas do documento."""
        logger.info("Extraindo tabelas do documento...")
        
        # Extrair todas as tabelas
        self.extracted_tables = self.table_extractor.extract_all_tables()
        
        # Converter para DataFrames
        table_dfs = self.table_extractor.tables_to_dataframes()
        
        # Identificar tipos de tabelas
        for df_info in table_dfs:
            df = df_info['dataframe']
            table_type = self.table_extractor.identify_table_type(df)
            df_info['type'] = table_type
            
            logger.info(f"Tabela na página {df_info['page']} identificada como: {table_type}")
        
        # Salvar tabelas como CSV
        if table_dfs:
            csv_dir = os.path.join(self.output_dir, 'tabelas')
            self.table_extractor.save_tables_to_csv(csv_dir)
    
    def _extract_structured_data(self):
        """Extrai dados estruturados das seções identificadas."""
        logger.info("Extraindo dados estruturados...")
        
        # Extrair identificação do edital
        if 'header' in self.extracted_sections:
            self.data_extractor.extract_identification(self.extracted_sections['header'])
        
        # Extrair cronograma
        if 'cronograma' in self.extracted_sections:
            self.data_extractor.extract_schedule(self.extracted_sections['cronograma'])
        
        # Extrair informações de inscrição
        if 'inscricao' in self.extracted_sections:
            self.data_extractor.extract_registration_info(self.extracted_sections['inscricao'])
        
        # Extrair cargos
        if 'cargos' in self.extracted_sections:
            self.data_extractor.extract_positions(self.extracted_sections['cargos'])
        
        # Extrair vagas
        if 'vagas' in self.extracted_sections:
            self.data_extractor.extract_vacancies(self.extracted_sections['vagas'])
        
        # Extrair conteúdo programático
        if 'conteudo_programatico' in self.extracted_sections:
            self.data_extractor.extract_syllabus(self.extracted_sections['conteudo_programatico'])
        
        # Obter todos os dados extraídos
        self.extracted_data = self.data_extractor.get_extracted_data()
        
        logger.info("Extração de dados estruturados concluída.")
    
    def _save_results(self):
        """Salva os resultados da extração."""
        # Salvar texto extraído
        text_output = os.path.join(self.output_dir, 'texto_extraido.txt')
        with open(text_output, 'w', encoding='utf-8') as f:
            for page_num in sorted(self.extracted_text.keys()):
                f.write(f"=== PÁGINA {page_num + 1} ===\n")
                f.write(self.extracted_text[page_num]['text'])
                f.write("\n\n")
        
        # Salvar seções extraídas
        sections_output = os.path.join(self.output_dir, 'secoes_extraidas.txt')
        with open(sections_output, 'w', encoding='utf-8') as f:
            for section_name, section_text in self.extracted_sections.items():
                f.write(f"=== SEÇÃO: {section_name} ===\n")
                f.write(section_text)
                f.write("\n\n")
        
        # Salvar dados estruturados
        data_output = os.path.join(self.output_dir, 'dados_extraidos.json')
        with open(data_output, 'w', encoding='utf-8') as f:
            json.dump(self.extracted_data, f, ensure_ascii=False, indent=4)
        
        logger.info(f"Resultados salvos em: {self.output_dir}")
        
        return {
            'text_file': text_output,
            'sections_file': sections_output,
            'data_file': data_output
        }
