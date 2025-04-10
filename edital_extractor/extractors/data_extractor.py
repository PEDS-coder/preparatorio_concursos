"""
Extrator de dados estruturados de editais.
"""

import logging
import re
from ..utils.regex_patterns import (
    find_all_dates, find_all_money_values, KEYWORDS,
    DATE_PATTERN_SLASH, DATE_PATTERN_DASH, DATE_RANGE_PATTERN, MONEY_PATTERN
)

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class DataExtractor:
    """Classe para extrair dados estruturados de editais."""
    
    def __init__(self):
        """Inicializa o extrator de dados."""
        self.extracted_data = {
            'identificacao': {},
            'cronograma': [],
            'inscricao': {},
            'cargos': [],
            'vagas': {},
            'requisitos': {},
            'remuneracao': {},
            'conteudo_programatico': {}
        }
    
    def extract_identification(self, text):
        """
        Extrai informações de identificação do edital.
        
        Args:
            text (str): Texto a ser analisado.
            
        Returns:
            dict: Informações de identificação extraídas.
        """
        identification = {}
        
        # Extrair número do edital
        edital_pattern = re.compile(r'EDITAL\s+(?:N[º°\.])?\s*(\d+[/-]\d{4})', re.IGNORECASE)
        edital_match = edital_pattern.search(text)
        if edital_match:
            identification['numero_edital'] = edital_match.group(1)
        
        # Extrair nome do órgão/instituição
        # Geralmente está nas primeiras linhas do documento
        lines = text.split('\n')[:10]  # Primeiras 10 linhas
        for line in lines:
            line = line.strip()
            if len(line) > 5 and not line.startswith('EDITAL'):
                identification['orgao'] = line
                break
        
        # Extrair ano do concurso (do número do edital ou do texto)
        year_pattern = re.compile(r'(?:CONCURSO|SELE[ÇC][ÃA]O).*?(\d{4})', re.IGNORECASE)
        year_match = year_pattern.search(text)
        if year_match:
            identification['ano'] = year_match.group(1)
        
        # Extrair banca organizadora
        bancas = ['FGV', 'CEBRASPE', 'CESPE', 'FCC', 'VUNESP', 'CESGRANRIO', 'IBFC', 'IADES', 'AOCP']
        for banca in bancas:
            if re.search(r'\b' + re.escape(banca) + r'\b', text, re.IGNORECASE):
                identification['banca'] = banca
                break
        
        self.extracted_data['identificacao'] = identification
        return identification
    
    def extract_schedule(self, text):
        """
        Extrai informações de cronograma do edital.
        
        Args:
            text (str): Texto a ser analisado.
            
        Returns:
            list: Lista de eventos do cronograma.
        """
        schedule = []
        
        # Procurar por padrões de data
        dates = find_all_dates(text)
        
        # Procurar por linhas que contêm datas e descrições de eventos
        lines = text.split('\n')
        for line in lines:
            line = line.strip()
            
            # Verificar se a linha contém uma data
            date_match_slash = DATE_PATTERN_SLASH.search(line)
            date_match_dash = DATE_PATTERN_DASH.search(line)
            date_range_match = DATE_RANGE_PATTERN.search(line)
            
            if date_match_slash or date_match_dash or date_range_match:
                # Extrair a data e a descrição do evento
                if date_range_match:
                    date = date_range_match.group(0)
                    # Remover a data da linha para obter a descrição
                    description = line.replace(date, '').strip()
                elif date_match_slash:
                    date = date_match_slash.group(0)
                    description = line.replace(date, '').strip()
                else:
                    date = date_match_dash.group(0)
                    description = line.replace(date, '').strip()
                
                # Limpar a descrição (remover pontuação no início)
                description = re.sub(r'^[:\-–—\s]+', '', description)
                
                if description:  # Só adicionar se tiver uma descrição
                    schedule.append({
                        'data': date,
                        'descricao': description
                    })
        
        self.extracted_data['cronograma'] = schedule
        return schedule
    
    def extract_registration_info(self, text):
        """
        Extrai informações de inscrição do edital.
        
        Args:
            text (str): Texto a ser analisado.
            
        Returns:
            dict: Informações de inscrição extraídas.
        """
        registration_info = {}
        
        # Extrair período de inscrição
        for keyword in KEYWORDS['periodo_inscricao']:
            pattern = re.compile(r'(?:' + re.escape(keyword) + r').*?(\d{1,2}/\d{1,2}/\d{4})\s*(?:a|até|e)\s*(\d{1,2}/\d{1,2}/\d{4})', re.IGNORECASE)
            match = pattern.search(text)
            if match:
                registration_info['periodo_inicio'] = match.group(1)
                registration_info['periodo_fim'] = match.group(2)
                break
        
        # Extrair taxa de inscrição
        for keyword in KEYWORDS['taxa_inscricao']:
            pattern = re.compile(r'(?:' + re.escape(keyword) + r').*?R\$\s?(\d{1,3}(?:\.\d{3})*,\d{2})', re.IGNORECASE)
            match = pattern.search(text)
            if match:
                registration_info['taxa'] = match.group(1)
                break
        
        # Se não encontrou com keywords, procurar por padrões de valor monetário próximos a palavras-chave
        if 'taxa' not in registration_info:
            lines = text.split('\n')
            for i, line in enumerate(lines):
                if any(keyword in line.lower() for keyword in ['taxa', 'inscrição', 'pagamento']):
                    # Verificar esta linha e as próximas 3 linhas
                    for j in range(i, min(i+4, len(lines))):
                        money_match = MONEY_PATTERN.search(lines[j])
                        if money_match:
                            registration_info['taxa'] = money_match.group(1)
                            break
                    if 'taxa' in registration_info:
                        break
        
        self.extracted_data['inscricao'] = registration_info
        return registration_info
    
    def extract_positions(self, text):
        """
        Extrai informações sobre cargos do edital.
        
        Args:
            text (str): Texto a ser analisado.
            
        Returns:
            list: Lista de cargos extraídos.
        """
        positions = []
        
        # Padrão para identificar cargos (geralmente em maiúsculas ou com formatação específica)
        cargo_pattern = re.compile(r'(?:CARGO|FUNÇÃO)(?:\s*:|\s+DE|\s+)\s*([A-ZÁÀÂÃÉÈÊÍÏÓÔÕÖÚÇÑ\s]+)(?:\s*-|\s*:|\s*\n)', re.IGNORECASE)
        cargo_matches = cargo_pattern.finditer(text)
        
        for match in cargo_matches:
            cargo_nome = match.group(1).strip()
            
            # Evitar falsos positivos (linhas muito curtas ou muito longas)
            if 3 < len(cargo_nome) < 100:
                # Procurar requisitos e remuneração próximos ao cargo
                start_pos = match.end()
                end_pos = text.find('CARGO', start_pos)
                if end_pos == -1:
                    end_pos = len(text)
                
                cargo_section = text[start_pos:end_pos]
                
                # Extrair requisitos
                requisitos = ""
                for keyword in KEYWORDS['requisitos']:
                    req_pattern = re.compile(r'(?:' + re.escape(keyword) + r')(?:\s*:|\s*-|\s*)\s*(.*?)(?:\n\s*\n|\n(?:[A-Z][a-z]+:))', re.IGNORECASE | re.DOTALL)
                    req_match = req_pattern.search(cargo_section)
                    if req_match:
                        requisitos = req_match.group(1).strip()
                        break
                
                # Extrair remuneração
                remuneracao = ""
                money_matches = MONEY_PATTERN.findall(cargo_section)
                if money_matches:
                    for keyword in KEYWORDS['remuneracao']:
                        if keyword.lower() in cargo_section.lower():
                            # Encontrar o valor monetário mais próximo da palavra-chave
                            keyword_pos = cargo_section.lower().find(keyword.lower())
                            closest_money = None
                            min_distance = float('inf')
                            
                            for money_match in money_matches:
                                money_str = f"R$ {money_match[0]}"
                                money_pos = cargo_section.find(money_str)
                                if money_pos != -1:
                                    distance = abs(money_pos - keyword_pos)
                                    if distance < min_distance:
                                        min_distance = distance
                                        closest_money = money_match[0]
                            
                            if closest_money:
                                remuneracao = closest_money
                                break
                
                positions.append({
                    'nome': cargo_nome,
                    'requisitos': requisitos,
                    'remuneracao': remuneracao
                })
        
        self.extracted_data['cargos'] = positions
        return positions
    
    def extract_vacancies(self, text):
        """
        Extrai informações sobre vagas do edital.
        
        Args:
            text (str): Texto a ser analisado.
            
        Returns:
            dict: Informações sobre vagas extraídas.
        """
        vacancies = {}
        
        # Padrão para identificar número de vagas
        vagas_pattern = re.compile(r'(\d+)\s+(?:vagas|vaga)', re.IGNORECASE)
        vagas_matches = vagas_pattern.finditer(text)
        
        for match in vagas_matches:
            # Procurar o cargo associado a essas vagas
            start_pos = max(0, match.start() - 200)  # Olhar até 200 caracteres antes
            context = text[start_pos:match.start()]
            
            # Procurar por um nome de cargo no contexto
            cargo_pattern = re.compile(r'(?:CARGO|FUNÇÃO)(?:\s*:|\s+DE|\s+)\s*([A-ZÁÀÂÃÉÈÊÍÏÓÔÕÖÚÇÑ\s]+)(?:\s*-|\s*:|\s*\n)', re.IGNORECASE)
            cargo_match = cargo_pattern.search(context)
            
            if cargo_match:
                cargo_nome = cargo_match.group(1).strip()
                num_vagas = int(match.group(1))
                
                # Verificar se já temos este cargo
                if cargo_nome in vacancies:
                    # Atualizar apenas se o novo número for maior
                    if num_vagas > vacancies[cargo_nome]['total']:
                        vacancies[cargo_nome]['total'] = num_vagas
                else:
                    vacancies[cargo_nome] = {
                        'total': num_vagas,
                        'ampla_concorrencia': 0,
                        'pcd': 0,
                        'negros': 0
                    }
                
                # Procurar distribuição de vagas (AC, PCD, Negros)
                # Ampla Concorrência
                ac_pattern = re.compile(r'(\d+)\s+(?:vaga|vagas)?\s*(?:para)?\s*(?:ampla\s+concorrência|AC)', re.IGNORECASE)
                ac_match = ac_pattern.search(text[match.start():match.start() + 500])
                if ac_match:
                    vacancies[cargo_nome]['ampla_concorrencia'] = int(ac_match.group(1))
                
                # PCD
                pcd_pattern = re.compile(r'(\d+)\s+(?:vaga|vagas)?\s*(?:para)?\s*(?:pessoa|candidato)?\s*(?:com)?\s*(?:deficiência|PCD|PcD)', re.IGNORECASE)
                pcd_match = pcd_pattern.search(text[match.start():match.start() + 500])
                if pcd_match:
                    vacancies[cargo_nome]['pcd'] = int(pcd_match.group(1))
                
                # Negros
                negros_pattern = re.compile(r'(\d+)\s+(?:vaga|vagas)?\s*(?:para)?\s*(?:pessoa|candidato)?\s*(?:negra|negro|preta|preto|parda|pardo)', re.IGNORECASE)
                negros_match = negros_pattern.search(text[match.start():match.start() + 500])
                if negros_match:
                    vacancies[cargo_nome]['negros'] = int(negros_match.group(1))
        
        self.extracted_data['vagas'] = vacancies
        return vacancies
    
    def extract_syllabus(self, text):
        """
        Extrai conteúdo programático do edital.
        
        Args:
            text (str): Texto a ser analisado.
            
        Returns:
            dict: Conteúdo programático extraído.
        """
        syllabus = {
            'conhecimentos_basicos': [],
            'conhecimentos_especificos': {}
        }
        
        # Dividir o texto em linhas para análise
        lines = text.split('\n')
        
        # Variáveis para controle do estado atual
        current_section = None
        current_cargo = None
        current_discipline = None
        current_topics = []
        
        # Padrões para identificar seções e disciplinas
        section_patterns = {
            'basicos': re.compile(r'\b(CONHECIMENTOS\s+B[ÁA]SICOS|CONHECIMENTOS\s+GERAIS)\b', re.IGNORECASE),
            'especificos': re.compile(r'\b(CONHECIMENTOS\s+ESPEC[ÍI]FICOS)(?:\s*(?:PARA|DO|DE|-)?\s*(.+))?\b', re.IGNORECASE)
        }
        
        discipline_pattern = re.compile(r'^[A-ZÁÀÂÃÉÈÊÍÏÓÔÕÖÚÇÑ\s]{3,50}:?$')
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            # Verificar se é uma seção de conhecimentos básicos
            basicos_match = section_patterns['basicos'].search(line)
            if basicos_match:
                # Salvar tópicos anteriores, se houver
                if current_discipline and current_topics:
                    if current_section == 'basicos':
                        syllabus['conhecimentos_basicos'].append({
                            'disciplina': current_discipline,
                            'topicos': current_topics
                        })
                    elif current_section == 'especificos' and current_cargo:
                        if current_cargo not in syllabus['conhecimentos_especificos']:
                            syllabus['conhecimentos_especificos'][current_cargo] = []
                        syllabus['conhecimentos_especificos'][current_cargo].append({
                            'disciplina': current_discipline,
                            'topicos': current_topics
                        })
                
                current_section = 'basicos'
                current_discipline = None
                current_topics = []
                continue
            
            # Verificar se é uma seção de conhecimentos específicos
            especificos_match = section_patterns['especificos'].search(line)
            if especificos_match:
                # Salvar tópicos anteriores, se houver
                if current_discipline and current_topics:
                    if current_section == 'basicos':
                        syllabus['conhecimentos_basicos'].append({
                            'disciplina': current_discipline,
                            'topicos': current_topics
                        })
                    elif current_section == 'especificos' and current_cargo:
                        if current_cargo not in syllabus['conhecimentos_especificos']:
                            syllabus['conhecimentos_especificos'][current_cargo] = []
                        syllabus['conhecimentos_especificos'][current_cargo].append({
                            'disciplina': current_discipline,
                            'topicos': current_topics
                        })
                
                current_section = 'especificos'
                current_cargo = especificos_match.group(2).strip() if especificos_match.group(2) else None
                current_discipline = None
                current_topics = []
                continue
            
            # Verificar se é uma disciplina
            if discipline_pattern.match(line) and len(line) < 50:
                # Salvar tópicos anteriores, se houver
                if current_discipline and current_topics:
                    if current_section == 'basicos':
                        syllabus['conhecimentos_basicos'].append({
                            'disciplina': current_discipline,
                            'topicos': current_topics
                        })
                    elif current_section == 'especificos' and current_cargo:
                        if current_cargo not in syllabus['conhecimentos_especificos']:
                            syllabus['conhecimentos_especificos'][current_cargo] = []
                        syllabus['conhecimentos_especificos'][current_cargo].append({
                            'disciplina': current_discipline,
                            'topicos': current_topics
                        })
                
                current_discipline = line.rstrip(':')
                current_topics = []
                continue
            
            # Se não é seção nem disciplina, é um tópico
            if current_section and current_discipline:
                # Limpar marcadores de lista
                clean_line = re.sub(r'^\s*[\d\.\)\-•*]+\s*', '', line)
                if clean_line:
                    current_topics.append(clean_line)
        
        # Salvar os últimos tópicos, se houver
        if current_discipline and current_topics:
            if current_section == 'basicos':
                syllabus['conhecimentos_basicos'].append({
                    'disciplina': current_discipline,
                    'topicos': current_topics
                })
            elif current_section == 'especificos' and current_cargo:
                if current_cargo not in syllabus['conhecimentos_especificos']:
                    syllabus['conhecimentos_especificos'][current_cargo] = []
                syllabus['conhecimentos_especificos'][current_cargo].append({
                    'disciplina': current_discipline,
                    'topicos': current_topics
                })
        
        self.extracted_data['conteudo_programatico'] = syllabus
        return syllabus
    
    def get_extracted_data(self):
        """
        Obtém todos os dados extraídos.
        
        Returns:
            dict: Todos os dados extraídos.
        """
        return self.extracted_data
