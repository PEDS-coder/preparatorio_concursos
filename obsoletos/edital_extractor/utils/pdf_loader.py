"""
Utilitários para carregamento e análise inicial de PDFs.
"""

import os
import logging
import fitz  # PyMuPDF
import pdfplumber
from PIL import Image
import io

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class PDFLoader:
    """Classe para carregar e analisar PDFs."""
    
    def __init__(self, pdf_path):
        """
        Inicializa o carregador de PDF.
        
        Args:
            pdf_path (str): Caminho para o arquivo PDF.
        """
        self.pdf_path = pdf_path
        self.doc = None
        self.plumber_doc = None
        self.page_count = 0
        self.scanned_pages = []
        
        if not os.path.exists(pdf_path):
            raise FileNotFoundError(f"Arquivo PDF não encontrado: {pdf_path}")
        
        try:
            # Carregar com PyMuPDF
            self.doc = fitz.open(pdf_path)
            self.page_count = len(self.doc)
            logger.info(f"PDF '{pdf_path}' carregado com {self.page_count} páginas.")
            
            # Carregar com pdfplumber para extração de tabelas
            self.plumber_doc = pdfplumber.open(pdf_path)
            
        except Exception as e:
            logger.error(f"Erro ao carregar PDF {pdf_path}: {e}")
            raise
    
    def close(self):
        """Fecha os documentos PDF abertos."""
        if self.doc:
            self.doc.close()
        if self.plumber_doc:
            self.plumber_doc.close()
    
    def is_page_scanned(self, page_num, text_threshold=50):
        """
        Verifica se uma página parece ser digitalizada (baseada em imagem).
        
        Args:
            page_num (int): Número da página (0-based).
            text_threshold (int): Limite mínimo de caracteres para considerar uma página como texto.
            
        Returns:
            bool: True se a página parece ser digitalizada, False caso contrário.
        """
        if page_num >= self.page_count:
            logger.warning(f"Número de página {page_num} fora do intervalo (0-{self.page_count-1}).")
            return False
        
        page = self.doc[page_num]
        text = page.get_text("text")
        
        if len(text.strip()) < text_threshold:
            # Pouco ou nenhum texto extraído, verificar imagens
            images = page.get_images(full=True)
            if images:
                # Verificar se alguma imagem cobre uma área significativa da página
                page_area = page.rect.width * page.rect.height
                for img_info in images:
                    try:
                        img_bbox = page.get_image_bbox(img_info[0])
                        if img_bbox:
                            img_area = img_bbox.width * img_bbox.height
                            # Se uma imagem cobre mais de 50% da página, considerar digitalizada
                            if img_area / page_area > 0.5:
                                return True
                    except Exception as e:
                        logger.warning(f"Erro ao analisar imagem na página {page_num}: {e}")
            
            # Se não há texto e não há imagem grande, ainda pode ser digitalizada
            return True  # Suposição conservadora
        
        return False
    
    def analyze_document(self):
        """
        Analisa o documento para identificar páginas digitalizadas.
        
        Returns:
            dict: Informações sobre o documento, incluindo páginas digitalizadas.
        """
        self.scanned_pages = []
        
        for page_num in range(self.page_count):
            if self.is_page_scanned(page_num):
                self.scanned_pages.append(page_num)
                logger.info(f"Página {page_num + 1} parece ser digitalizada.")
        
        return {
            "total_pages": self.page_count,
            "scanned_pages": self.scanned_pages,
            "scanned_percentage": len(self.scanned_pages) / self.page_count * 100 if self.page_count > 0 else 0
        }
    
    def get_page_as_image(self, page_num, dpi=300):
        """
        Converte uma página do PDF em imagem.
        
        Args:
            page_num (int): Número da página (0-based).
            dpi (int): Resolução da imagem em DPI.
            
        Returns:
            PIL.Image: Objeto de imagem PIL ou None em caso de erro.
        """
        if page_num >= self.page_count:
            logger.warning(f"Número de página {page_num} fora do intervalo (0-{self.page_count-1}).")
            return None
        
        try:
            page = self.doc[page_num]
            pix = page.get_pixmap(matrix=fitz.Matrix(dpi/72, dpi/72))
            img_data = pix.tobytes("png")
            img = Image.open(io.BytesIO(img_data))
            return img
        except Exception as e:
            logger.error(f"Erro ao converter página {page_num} para imagem: {e}")
            return None
    
    def extract_text_with_layout(self, page_num, header_margin=50, footer_margin=50):
        """
        Extrai texto de uma página com informações de layout.
        
        Args:
            page_num (int): Número da página (0-based).
            header_margin (int): Margem superior a ignorar (para remover cabeçalhos).
            footer_margin (int): Margem inferior a ignorar (para remover rodapés).
            
        Returns:
            dict: Dicionário com blocos de texto e informações de layout.
        """
        if page_num >= self.page_count:
            logger.warning(f"Número de página {page_num} fora do intervalo (0-{self.page_count-1}).")
            return None
        
        try:
            page = self.doc[page_num]
            page_rect = page.rect
            
            # Definir área de recorte para excluir cabeçalho e rodapé
            clip_rect = fitz.Rect(
                page_rect.x0,
                page_rect.y0 + header_margin,
                page_rect.x1,
                page_rect.y1 - footer_margin
            )
            
            # Extrair texto com informações de layout
            page_dict = page.get_text("dict", clip=clip_rect, sort=True)
            return page_dict
        except Exception as e:
            logger.error(f"Erro ao extrair texto da página {page_num}: {e}")
            return None
