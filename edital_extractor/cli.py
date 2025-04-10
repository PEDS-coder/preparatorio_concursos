"""
Interface de linha de comando para o extrator de editais.
"""

import argparse
import logging
import os
import sys
import json
from .processors.pdf_processor import PDFProcessor

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def parse_args():
    """
    Analisa os argumentos da linha de comando.
    
    Returns:
        argparse.Namespace: Argumentos analisados.
    """
    parser = argparse.ArgumentParser(
        description='Extrator de dados de editais de concursos públicos em PDF.'
    )
    
    parser.add_argument(
        'pdf_path',
        help='Caminho para o arquivo PDF do edital.'
    )
    
    parser.add_argument(
        '-o', '--output-dir',
        help='Diretório de saída para os arquivos gerados. Padrão: mesmo diretório do PDF.'
    )
    
    parser.add_argument(
        '--no-ocr',
        action='store_true',
        help='Desativa o uso de OCR para páginas digitalizadas.'
    )
    
    parser.add_argument(
        '--debug',
        action='store_true',
        help='Ativa o modo de depuração (logs mais detalhados).'
    )
    
    return parser.parse_args()

def main():
    """Função principal da interface de linha de comando."""
    args = parse_args()
    
    # Configurar nível de log
    if args.debug:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Verificar se o arquivo PDF existe
    if not os.path.exists(args.pdf_path):
        logger.error(f"Arquivo PDF não encontrado: {args.pdf_path}")
        sys.exit(1)
    
    try:
        # Processar o PDF
        processor = PDFProcessor(
            pdf_path=args.pdf_path,
            output_dir=args.output_dir,
            use_ocr=not args.no_ocr
        )
        
        # Extrair dados
        extracted_data = processor.process()
        
        # Exibir resumo dos dados extraídos
        print("\n=== RESUMO DOS DADOS EXTRAÍDOS ===")
        
        # Identificação
        if extracted_data['identificacao']:
            print("\nIdentificação do Edital:")
            for key, value in extracted_data['identificacao'].items():
                print(f"  {key}: {value}")
        
        # Cronograma
        if extracted_data['cronograma']:
            print("\nCronograma:")
            for i, evento in enumerate(extracted_data['cronograma'][:5], 1):
                print(f"  {i}. {evento.get('data', 'N/A')} - {evento.get('descricao', 'N/A')}")
            if len(extracted_data['cronograma']) > 5:
                print(f"  ... e mais {len(extracted_data['cronograma']) - 5} eventos.")
        
        # Inscrição
        if extracted_data['inscricao']:
            print("\nInscrição:")
            for key, value in extracted_data['inscricao'].items():
                print(f"  {key}: {value}")
        
        # Cargos
        if extracted_data['cargos']:
            print("\nCargos:")
            for i, cargo in enumerate(extracted_data['cargos'][:5], 1):
                print(f"  {i}. {cargo.get('nome', 'N/A')}")
            if len(extracted_data['cargos']) > 5:
                print(f"  ... e mais {len(extracted_data['cargos']) - 5} cargos.")
        
        # Conteúdo Programático
        if extracted_data['conteudo_programatico']:
            print("\nConteúdo Programático:")
            if extracted_data['conteudo_programatico'].get('conhecimentos_basicos'):
                print(f"  Conhecimentos Básicos: {len(extracted_data['conteudo_programatico']['conhecimentos_basicos'])} disciplinas")
            if extracted_data['conteudo_programatico'].get('conhecimentos_especificos'):
                print(f"  Conhecimentos Específicos: {len(extracted_data['conteudo_programatico']['conhecimentos_especificos'])} cargos")
        
        print("\nArquivos gerados:")
        print(f"  Texto extraído: {os.path.join(processor.output_dir, 'texto_extraido.txt')}")
        print(f"  Seções extraídas: {os.path.join(processor.output_dir, 'secoes_extraidas.txt')}")
        print(f"  Dados estruturados: {os.path.join(processor.output_dir, 'dados_extraidos.json')}")
        
        if os.path.exists(os.path.join(processor.output_dir, 'tabelas')):
            print(f"  Tabelas extraídas: {os.path.join(processor.output_dir, 'tabelas')}")
        
        print("\nExtração concluída com sucesso!")
        
    except Exception as e:
        logger.error(f"Erro ao processar o edital: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
