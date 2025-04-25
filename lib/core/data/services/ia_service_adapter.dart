import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'interfaces/ia_service_interface.dart';
import '../../data/models/flashcard.dart';

class IAServiceAdapter implements IAServiceInterface {
  final IAServiceInterface _iaService;

  IAServiceAdapter(this._iaService);

  @override
  String? get apiKey => _iaService.apiKey;

  @override
  String get apiType => _iaService.apiType;

  @override
  bool get isConfigured => _iaService.isConfigured;

  @override
  Future<bool> configurarApiKey(String apiKey) {
    return _iaService.configurarApiKey(apiKey);
  }

  @override
  void setApiType(String apiType) {
    _iaService.setApiType(apiType);
  }

  @override
  Future<void> initCache() {
    return _iaService.initCache();
  }

  @override
  Future<String> analisarTexto(String texto, {String? prompt}) {
    return _iaService.analisarTexto(texto, prompt: prompt);
  }

  @override
  Future<String> gerarTexto(String prompt) {
    return _iaService.gerarTexto(prompt);
  }

  @override
  Future<Map<String, dynamic>> setApiKey(String apiKey, String apiType) {
    return _iaService.setApiKey(apiKey, apiType);
  }

  @override
  Future<bool> testApiKey(String apiKey, String apiType) {
    return _iaService.testApiKey(apiKey, apiType);
  }

  @override
  Future<bool> testApiConnection() {
    return _iaService.testApiConnection();
  }

  @override
  Future<Map<String, dynamic>> configureOAuth(String clientId, String clientSecret) {
    return _iaService.configureOAuth(clientId, clientSecret);
  }

  @override
  Future<Map<String, dynamic>> authenticateWithGoogle() {
    return _iaService.authenticateWithGoogle();
  }

  @override
  Future<String> callApi(String prompt) {
    return _iaService.callApi(prompt);
  }

  @override
  Future<String> callApiWithPrompt(String prompt) {
    return _iaService.callApiWithPrompt(prompt);
  }

  @override
  Future<Map<String, dynamic>?> gerarRespostaJson(String prompt) {
    return _iaService.gerarRespostaJson(prompt);
  }

  @override
  Future<String> analisarEditalPdf(Uint8List pdfBytes, {String? pdfName}) {
    return _iaService.analisarEditalPdf(pdfBytes, pdfName: pdfName);
  }

  @override
  Future<String> extrairCargosEdital(Uint8List pdfBytes, {String? pdfName}) {
    return _iaService.extrairCargosEdital(pdfBytes, pdfName: pdfName);
  }

  @override
  Future<String> extrairInfoBasicasEdital(Uint8List pdfBytes, {String? pdfName}) {
    return _iaService.extrairInfoBasicasEdital(pdfBytes, pdfName: pdfName);
  }

  @override
  Future<Map<String, dynamic>> extrairConcursoConteudo({required Uint8List pdfBytes, required String cargoAlvo, String? pdfName}) {
    return _iaService.extrairConcursoConteudo(pdfBytes: pdfBytes, cargoAlvo: cargoAlvo, pdfName: pdfName);
  }



  @override
  Future<String> gerarResumo(String texto) {
    return _iaService.gerarResumo(texto);
  }

  @override
  Future<String> gerarEsquema({required String texto, String? titulo}) {
    return _iaService.gerarEsquema(texto: texto, titulo: titulo);
  }

  @override
  Future<String> gerarQuestoes({required String texto, required String materia, required String dificuldade, required int quantidade}) {
    return _iaService.gerarQuestoes(texto: texto, materia: materia, dificuldade: dificuldade, quantidade: quantidade);
  }

  @override
  Future<List<Flashcard>> gerarFlashcards({required String userId, String? editalId, required String materia, required String texto}) {
    return _iaService.gerarFlashcards(userId: userId, editalId: editalId, materia: materia, texto: texto);
  }

  @override
  bool isWithinTokenLimit(String texto) {
    return _iaService.isWithinTokenLimit(texto);
  }

  @override
  Future<bool> clearCache() {
    return _iaService.clearCache();
  }



  @override
  Future<String> gerarPlanoEstudos({required String cargoAlvo, required Map<String, dynamic> dadosCargo}) {
    return _iaService.gerarPlanoEstudos(cargoAlvo: cargoAlvo, dadosCargo: dadosCargo);
  }

  @override
  Future<Map<String, dynamic>> analisarEditalPrimeiraChamada(
    List<File> files,
    Function(String, double) onProgress,
  ) {
    return _iaService.analisarEditalPrimeiraChamada(files, onProgress);
  }

  @override
  Future<Map<String, dynamic>> analisarEditalSegundaChamada(
    String editalId,
    String cargoId,
    String cargoNome,
    Function(String, double) onProgress,
  ) {
    return _iaService.analisarEditalSegundaChamada(editalId, cargoId, cargoNome, onProgress);
  }

  @override
  Future<String> processarPdf(String prompt, Uint8List pdfBytes, {String? pdfName}) {
    return _iaService.processarPdf(prompt, pdfBytes, pdfName: pdfName);
  }
}
