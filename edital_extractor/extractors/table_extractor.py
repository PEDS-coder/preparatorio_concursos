"""
Extrator de tabelas de editais.
"""

import logging
import pandas as pd
import pdfplumber
import os

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class TableExtractor:
    """Classe para extrair tabelas de editais."""
    
    def __init__(self, pdf_path):
        """
        Inicializa o extrator de tabelas.
        
        Args:
            pdf_path (str): Caminho para o arquivo PDF.
        """
        self.pdf_path = pdf_path
        self.tables = []
        self.table_settings = {
            "vertical_strategy": "lines",
            "horizontal_strategy": "lines",
            "snap_tolerance": 3,
            "join_tolerance": 3,
            "edge_min_length": 3,
            "min_words_vertical": 3,
            "min_words_horizontal": 1
        }
    
    def extract_tables_from_page(self, page_num, bbox=None, settings=None):
        """
        Extrai tabelas de uma página específica.
        
        Args:
            page_num (int): Número da página (0-based).
            bbox (tuple): Coordenadas da área de recorte (x0, top, x1, bottom).
            settings (dict): Configurações para extração de tabelas.
            
        Returns:
            list: Lista de tabelas extraídas.
        """
        tables = []
        
        try:
            with pdfplumber.open(self.pdf_path) as pdf:
                if page_num >= len(pdf.pages):
                    logger.warning(f"Número de página {page_num} fora do intervalo (0-{len(pdf.pages)-1}).")
                    return tables
                
                page = pdf.pages[page_num]
                target_page = page
                
                if bbox:
                    # Recortar a página para a área especificada
                    target_page = page.crop(bbox)
                
                # Usar configurações personalizadas ou padrão
                current_settings = settings if settings else self.table_settings
                
                # Extrair tabelas
                extracted = target_page.extract_tables(table_settings=current_settings)
                
                if extracted:
                    for table in extracted:
                        # Filtrar tabelas vazias ou muito pequenas
                        if table and len(table) > 1 and len(table[0]) > 1:
                            tables.append(table)
                            logger.info(f"Tabela extraída da página {page_num + 1}: {len(table)}x{len(table[0])}")
                
        except Exception as e:
            logger.error(f"Erro ao extrair tabelas da página {page_num + 1}: {e}")
        
        return tables
    
    def extract_all_tables(self, page_range=None, settings=None):
        """
        Extrai todas as tabelas do documento.
        
        Args:
            page_range (tuple): Intervalo de páginas (início, fim) ou None para todas.
            settings (dict): Configurações para extração de tabelas.
            
        Returns:
            list: Lista de tabelas extraídas.
        """
        all_tables = []
        
        try:
            with pdfplumber.open(self.pdf_path) as pdf:
                total_pages = len(pdf.pages)
                
                # Determinar o intervalo de páginas
                start_page = 0
                end_page = total_pages
                
                if page_range:
                    start_page = max(0, page_range[0])
                    end_page = min(total_pages, page_range[1] + 1)
                
                logger.info(f"Extraindo tabelas das páginas {start_page + 1} a {end_page}...")
                
                for page_num in range(start_page, end_page):
                    tables = self.extract_tables_from_page(page_num, settings=settings)
                    
                    for table in tables:
                        all_tables.append({
                            'page': page_num + 1,
                            'data': table
                        })
        
        except Exception as e:
            logger.error(f"Erro ao extrair todas as tabelas: {e}")
        
        self.tables = all_tables
        return all_tables
    
    def try_alternative_settings(self, page_num, bbox=None):
        """
        Tenta extrair tabelas com configurações alternativas.
        
        Args:
            page_num (int): Número da página (0-based).
            bbox (tuple): Coordenadas da área de recorte (x0, top, x1, bottom).
            
        Returns:
            list: Lista de tabelas extraídas.
        """
        # Lista de configurações alternativas para tentar
        alternative_settings = [
            # Estratégia baseada em texto
            {
                "vertical_strategy": "text",
                "horizontal_strategy": "text",
                "snap_tolerance": 5,
                "join_tolerance": 5
            },
            # Estratégia mista
            {
                "vertical_strategy": "lines",
                "horizontal_strategy": "text",
                "snap_tolerance": 3,
                "join_tolerance": 3
            },
            # Estratégia com tolerância maior
            {
                "vertical_strategy": "lines",
                "horizontal_strategy": "lines",
                "snap_tolerance": 10,
                "join_tolerance": 10,
                "edge_min_length": 5
            }
        ]
        
        best_tables = []
        
        for settings in alternative_settings:
            tables = self.extract_tables_from_page(page_num, bbox, settings)
            
            # Se encontrou tabelas, verificar se são melhores que as anteriores
            if tables and (not best_tables or len(tables) > len(best_tables) or 
                          (len(tables) == len(best_tables) and 
                           sum(len(t) for t in tables) > sum(len(t) for t in best_tables))):
                best_tables = tables
        
        return best_tables
    
    def tables_to_dataframes(self):
        """
        Converte as tabelas extraídas em DataFrames do pandas.
        
        Returns:
            list: Lista de DataFrames.
        """
        dataframes = []
        
        for table_info in self.tables:
            table = table_info['data']
            page = table_info['page']
            
            if table and len(table) > 0:
                # Usar a primeira linha como cabeçalho
                header = table[0]
                
                # Verificar se o cabeçalho tem células vazias
                has_empty_headers = any(not h for h in header)
                
                if has_empty_headers:
                    # Gerar cabeçalhos genéricos
                    header = [f"Col{i}" if not h else h for i, h in enumerate(header)]
                
                # Criar DataFrame
                df = pd.DataFrame(table[1:], columns=header)
                
                # Adicionar informação da página
                df_with_info = {
                    'page': page,
                    'dataframe': df,
                    'rows': len(df),
                    'columns': len(df.columns)
                }
                
                dataframes.append(df_with_info)
        
        return dataframes
    
    def save_tables_to_csv(self, output_dir):
        """
        Salva as tabelas extraídas como arquivos CSV.
        
        Args:
            output_dir (str): Diretório de saída.
            
        Returns:
            list: Lista de caminhos para os arquivos CSV salvos.
        """
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)
        
        csv_files = []
        dataframes = self.tables_to_dataframes()
        
        for i, df_info in enumerate(dataframes):
            df = df_info['dataframe']
            page = df_info['page']
            
            # Criar nome de arquivo
            filename = f"tabela_pagina_{page}_num_{i+1}.csv"
            filepath = os.path.join(output_dir, filename)
            
            # Salvar como CSV
            df.to_csv(filepath, index=False, encoding='utf-8-sig')
            csv_files.append(filepath)
            
            logger.info(f"Tabela salva em: {filepath}")
        
        return csv_files
    
    def identify_table_type(self, dataframe):
        """
        Tenta identificar o tipo de tabela com base no conteúdo.
        
        Args:
            dataframe (pandas.DataFrame): DataFrame a ser analisado.
            
        Returns:
            str: Tipo de tabela identificado ou "desconhecido".
        """
        # Converter todas as colunas para string para facilitar a busca
        df_str = dataframe.astype(str)
        
        # Verificar se é uma tabela de cargos/vagas
        if any('cargo' in col.lower() for col in df_str.columns):
            if any('vaga' in col.lower() for col in df_str.columns):
                return "cargos_vagas"
            return "cargos"
        
        # Verificar se é uma tabela de cronograma
        if any('data' in col.lower() for col in df_str.columns) and any('atividade' in col.lower() or 'evento' in col.lower() for col in df_str.columns):
            return "cronograma"
        
        # Verificar se é uma tabela de remuneração
        if any('remuneração' in col.lower() or 'salário' in col.lower() or 'vencimento' in col.lower() for col in df_str.columns):
            return "remuneracao"
        
        # Verificar conteúdo das células
        all_text = ' '.join([' '.join(df_str[col].tolist()) for col in df_str.columns])
        
        if 'vaga' in all_text.lower() and ('ampla' in all_text.lower() or 'concorrência' in all_text.lower()):
            return "vagas"
        
        if any(date_term in all_text.lower() for date_term in ['data', 'período', 'prazo']):
            if any(event_term in all_text.lower() for event_term in ['atividade', 'evento', 'etapa']):
                return "cronograma"
        
        return "desconhecido"
