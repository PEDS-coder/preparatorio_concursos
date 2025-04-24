"""
Extrator de seções de editais.
"""

import logging
import re
from collections import defaultdict
from ..utils.regex_patterns import SECTION_PATTERNS, find_section_by_keywords

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class SectionExtractor:
    """Classe para extrair e identificar seções de editais."""
    
    def __init__(self):
        """Inicializa o extrator de seções."""
        self.sections = defaultdict(list)
        self.section_boundaries = {}
    
    def extract_sections_from_blocks(self, blocks, page_num=0):
        """
        Extrai seções de uma lista de blocos de texto.
        
        Args:
            blocks (list): Lista de blocos de texto com informações de layout.
            page_num (int): Número da página (para referência).
            
        Returns:
            dict: Mapeamento de seções identificadas.
        """
        current_section = "header"
        current_blocks = []
        
        # Analisar cada bloco para identificar possíveis cabeçalhos de seção
        for block_idx, block in enumerate(blocks):
            if block['type'] == 0:  # Bloco de texto
                block_text = self._get_block_text(block)
                
                # Verificar se é um potencial título de seção
                section_type = self._identify_section_type(block_text, block)
                
                if section_type:
                    # Salvar a seção anterior
                    if current_blocks:
                        self.sections[current_section].extend(current_blocks)
                        
                        # Registrar limites da seção (para referência)
                        if current_section not in self.section_boundaries:
                            self.section_boundaries[current_section] = []
                        self.section_boundaries[current_section].append({
                            'page': page_num,
                            'start_block': block_idx - len(current_blocks),
                            'end_block': block_idx - 1,
                            'blocks': current_blocks
                        })
                    
                    # Iniciar nova seção
                    current_section = section_type
                    current_blocks = [block]
                else:
                    current_blocks.append(block)
        
        # Adicionar a última seção
        if current_blocks:
            self.sections[current_section].extend(current_blocks)
            
            # Registrar limites da última seção
            if current_section not in self.section_boundaries:
                self.section_boundaries[current_section] = []
            self.section_boundaries[current_section].append({
                'page': page_num,
                'start_block': len(blocks) - len(current_blocks),
                'end_block': len(blocks) - 1,
                'blocks': current_blocks
            })
        
        return dict(self.sections)
    
    def _get_block_text(self, block):
        """
        Extrai o texto de um bloco.
        
        Args:
            block (dict): Bloco de texto.
            
        Returns:
            str: Texto do bloco.
        """
        try:
            text = ""
            for line in block.get('lines', []):
                for span in line.get('spans', []):
                    text += span.get('text', '')
            return text.strip()
        except Exception as e:
            logger.error(f"Erro ao extrair texto do bloco: {e}")
            return ""
    
    def _identify_section_type(self, text, block):
        """
        Identifica o tipo de seção com base no texto e características do bloco.
        
        Args:
            text (str): Texto do bloco.
            block (dict): Bloco de texto com informações de layout.
            
        Returns:
            str: Tipo de seção identificado ou None.
        """
        # Verificar se o texto é curto (potencial título)
        if len(text) > 150:
            return None
        
        # Verificar se o texto está em maiúsculas (comum em títulos)
        is_uppercase = text.isupper() or text.upper() == text
        
        # Verificar se o bloco tem características de título (fonte maior, negrito, etc.)
        is_title_format = self._check_title_format(block)
        
        # Se tem características de título, verificar padrões de seção conhecidos
        if (is_uppercase or is_title_format) and len(text) < 100:
            for section_type, pattern in SECTION_PATTERNS.items():
                if pattern.search(text):
                    logger.info(f"Seção identificada: {section_type} - '{text}'")
                    return section_type
        
        return None
    
    def _check_title_format(self, block):
        """
        Verifica se um bloco tem características de formatação de título.
        
        Args:
            block (dict): Bloco de texto com informações de layout.
            
        Returns:
            bool: True se o bloco tem características de título, False caso contrário.
        """
        try:
            # Verificar se há informações de fonte
            for line in block.get('lines', []):
                for span in line.get('spans', []):
                    # Verificar se a fonte é maior que o normal ou em negrito
                    font_size = span.get('size', 0)
                    font_name = span.get('font', '').lower()
                    
                    # Tamanho de fonte maior que 12 ou contém 'bold' no nome da fonte
                    if font_size > 12 or 'bold' in font_name or 'negrito' in font_name:
                        return True
            
            return False
        except Exception as e:
            logger.error(f"Erro ao verificar formato de título: {e}")
            return False
    
    def get_section_text(self, section_type):
        """
        Obtém o texto completo de uma seção.
        
        Args:
            section_type (str): Tipo de seção.
            
        Returns:
            str: Texto completo da seção.
        """
        if section_type not in self.sections:
            return ""
        
        text = ""
        for block in self.sections[section_type]:
            text += self._get_block_text(block) + "\n"
        
        return text.strip()
    
    def get_all_sections(self):
        """
        Obtém todas as seções identificadas.
        
        Returns:
            dict: Mapeamento de tipos de seção para seus textos.
        """
        result = {}
        for section_type in self.sections:
            result[section_type] = self.get_section_text(section_type)
        
        return result
