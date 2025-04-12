import os
import google.generativeai as genai

# Solicitar a API key do usuário
api_key = input("Digite sua API key do Google AI: ")

# Configurar a API
genai.configure(api_key=api_key)

# Listar modelos disponíveis
print("Modelos disponíveis:")
for model in genai.list_models():
    if 'generateContent' in model.supported_generation_methods:
        print(f"Nome: {model.name}")
        print(f"Versão: {model.version}")
        print(f"Métodos suportados: {model.supported_generation_methods}")
        print(f"Limite de tokens de entrada: {model.input_token_limit}")
        print(f"Limite de tokens de saída: {model.output_token_limit}")
        print("-" * 50)
