"""
Padrões de expressões regulares para extração de dados de editais.
"""

import re

# Padrões para datas
DATE_PATTERN_SLASH = re.compile(r'\b(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/(19\d{2}|20\d{2})\b')
DATE_PATTERN_DASH = re.compile(r'\b(0[1-9]|[12][0-9]|3[01])-(0[1-9]|1[0-2])-(19\d{2}|20\d{2})\b')
DATE_PATTERN_EXTENSO = re.compile(r'\b(0?[1-9]|[12][0-9]|3[01])\s+de\s+(janeiro|fevereiro|mar[çc]o|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro)\s+de\s+(19\d{2}|20\d{2})\b', re.IGNORECASE)
DATE_RANGE_PATTERN = re.compile(r'\b(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/(19\d{2}|20\d{2})\s+a\s+(0[1-9]|[12][0-9]|3[01])/(0[1-9]|1[0-2])/(19\d{2}|20\d{2})\b')

# Padrões para valores monetários
MONEY_PATTERN = re.compile(r'R\$\s?(\d{1,3}(\.\d{3})*,\d{2})\b')

# Padrões para CNPJ
CNPJ_PATTERN = re.compile(r'\b\d{2}\.\d{3}\.\d{3}/\d{4}-\d{2}\b')

# Padrões para horários
TIME_PATTERN = re.compile(r'\b([01]\d|2[0-3]):([0-5]\d)\b')

# Padrões para marcadores de lista
LIST_MARKER_NUMERIC = re.compile(r'^\s*(\d+[\.\)])\s+')
LIST_MARKER_ALPHA = re.compile(r'^\s*([a-zA-Z][\.\)])\s+')
LIST_MARKER_ROMAN = re.compile(r'^\s*([ivxlcdm]+[\.\)])\s+', re.IGNORECASE)
LIST_MARKER_BULLET = re.compile(r'^\s*([*•-])\s+')

# Padrões para identificação de seções comuns em editais
SECTION_PATTERNS = {
    'identificacao': re.compile(r'EDITAL\s+(?:N[º°\.])?\s*(\d+[/-]\d{4})', re.IGNORECASE),
    'cronograma': re.compile(r'\b(CRONOGRAMA|DATAS\s+IMPORTANTES|CALEND[ÁA]RIO)\b', re.IGNORECASE),
    'inscricao': re.compile(r'\b(INSCRI[ÇC][ÃA]O|DAS\s+INSCRI[ÇC][ÕO]ES)\b', re.IGNORECASE),
    'cargos': re.compile(r'\b(CARGOS|DOS\s+CARGOS|QUADRO\s+DE\s+CARGOS)\b', re.IGNORECASE),
    'vagas': re.compile(r'\b(VAGAS|DAS\s+VAGAS|QUADRO\s+DE\s+VAGAS|DISTRIBUI[ÇC][ÃA]O\s+DAS\s+VAGAS)\b', re.IGNORECASE),
    'requisitos': re.compile(r'\b(REQUISITOS|DOS\s+REQUISITOS|REQUISITOS\s+M[ÍI]NIMOS)\b', re.IGNORECASE),
    'remuneracao': re.compile(r'\b(REMUNERA[ÇC][ÃA]O|DA\s+REMUNERA[ÇC][ÃA]O|VENCIMENTOS)\b', re.IGNORECASE),
    'conteudo_programatico': re.compile(r'\b(CONTE[ÚU]DO\s+PROGRAM[ÁA]TICO|ANEXO\s+.*CONTE[ÚU]DO|PROGRAMA\s+DE\s+PROVAS)\b', re.IGNORECASE),
    'conhecimentos_basicos': re.compile(r'\b(CONHECIMENTOS\s+B[ÁA]SICOS|CONHECIMENTOS\s+GERAIS)\b', re.IGNORECASE),
    'conhecimentos_especificos': re.compile(r'\b(CONHECIMENTOS\s+ESPEC[ÍI]FICOS)\b', re.IGNORECASE),
}

# Palavras-chave para informações específicas
KEYWORDS = {
    'taxa_inscricao': [
        'taxa de inscrição', 'valor da taxa', 'valor da inscrição', 
        'taxa de participação', 'valor a ser pago'
    ],
    'periodo_inscricao': [
        'período de inscrição', 'prazo para inscrição', 'data de inscrição',
        'inscrições serão realizadas', 'inscrições estarão abertas'
    ],
    'requisitos': [
        'requisitos', 'escolaridade', 'formação mínima', 'formação exigida',
        'pré-requisitos', 'qualificação necessária'
    ],
    'remuneracao': [
        'remuneração', 'vencimento básico', 'salário', 'vencimentos',
        'subsídio', 'valor do salário'
    ],
}

def find_all_dates(text):
    """
    Encontra todas as datas em um texto.
    
    Args:
        text (str): Texto a ser analisado.
        
    Returns:
        list: Lista de datas encontradas.
    """
    dates = []
    
    # Encontrar datas no formato DD/MM/AAAA
    dates.extend(DATE_PATTERN_SLASH.findall(text))
    
    # Encontrar datas no formato DD-MM-AAAA
    dates.extend(DATE_PATTERN_DASH.findall(text))
    
    # Encontrar datas por extenso
    dates.extend(DATE_PATTERN_EXTENSO.findall(text))
    
    # Encontrar intervalos de datas
    dates.extend(DATE_RANGE_PATTERN.findall(text))
    
    return dates

def find_all_money_values(text):
    """
    Encontra todos os valores monetários em um texto.
    
    Args:
        text (str): Texto a ser analisado.
        
    Returns:
        list: Lista de valores monetários encontrados.
    """
    return MONEY_PATTERN.findall(text)

def find_section_by_keywords(text, section_type):
    """
    Verifica se um texto contém palavras-chave de uma seção específica.
    
    Args:
        text (str): Texto a ser analisado.
        section_type (str): Tipo de seção a procurar.
        
    Returns:
        bool: True se encontrou palavras-chave da seção, False caso contrário.
    """
    if section_type in SECTION_PATTERNS:
        return bool(SECTION_PATTERNS[section_type].search(text))
    return False
