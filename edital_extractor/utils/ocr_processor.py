"""
Processador OCR para páginas digitalizadas.
"""

import logging
import os
import io
import numpy as np
from PIL import Image, ImageEnhance, ImageFilter

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class OCRProcessor:
    """Classe para processamento OCR de páginas digitalizadas."""
    
    def __init__(self, use_easyocr=True):
        """
        Inicializa o processador OCR.
        
        Args:
            use_easyocr (bool): Se True, usa EasyOCR. Se False, usa pytesseract.
        """
        self.use_easyocr = use_easyocr
        self.ocr_engine = None
        
        try:
            if use_easyocr:
                import easyocr
                logger.info("Inicializando EasyOCR (pode levar alguns segundos)...")
                self.ocr_engine = easyocr.Reader(['pt'], gpu=False)
                logger.info("EasyOCR inicializado com sucesso.")
            else:
                import pytesseract
                self.ocr_engine = pytesseract
                logger.info("Pytesseract configurado.")
        except ImportError as e:
            logger.error(f"Erro ao importar biblioteca OCR: {e}")
            logger.error("Instale com: pip install easyocr pytesseract")
            raise
        except Exception as e:
            logger.error(f"Erro ao inicializar OCR: {e}")
            raise
    
    def preprocess_image(self, image):
        """
        Pré-processa a imagem para melhorar a qualidade do OCR.
        
        Args:
            image (PIL.Image): Imagem a ser processada.
            
        Returns:
            PIL.Image: Imagem pré-processada.
        """
        try:
            # Converter para escala de cinza
            img_gray = image.convert('L')
            
            # Aumentar contraste
            enhancer = ImageEnhance.Contrast(img_gray)
            img_contrast = enhancer.enhance(2.0)
            
            # Aplicar filtro para reduzir ruído
            img_filtered = img_contrast.filter(ImageFilter.MedianFilter(size=3))
            
            # Binarização (opcional, pode ajudar em alguns casos)
            # threshold = 150
            # img_binary = img_filtered.point(lambda x: 0 if x < threshold else 255, '1')
            
            return img_filtered
        except Exception as e:
            logger.error(f"Erro no pré-processamento da imagem: {e}")
            return image  # Retorna a imagem original em caso de erro
    
    def perform_ocr(self, image, lang='por'):
        """
        Realiza OCR em uma imagem.
        
        Args:
            image (PIL.Image): Imagem para OCR.
            lang (str): Código do idioma (usado apenas com pytesseract).
            
        Returns:
            str: Texto extraído da imagem.
        """
        if not self.ocr_engine:
            logger.error("Motor OCR não inicializado.")
            return ""
        
        try:
            # Pré-processar a imagem
            processed_img = self.preprocess_image(image)
            
            if self.use_easyocr:
                # EasyOCR aceita imagem PIL diretamente
                results = self.ocr_engine.readtext(np.array(processed_img))
                # Extrair apenas o texto reconhecido
                text = "\n".join([res[1] for res in results])
            else:
                # Pytesseract
                text = self.ocr_engine.image_to_string(processed_img, lang=lang)
            
            return text
        except Exception as e:
            logger.error(f"Erro durante OCR: {e}")
            return ""
