import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'matrix_rain_animation.dart';
import 'space_travel_animation.dart';
import 'neural_network_animation.dart';
import 'data_processing_animation.dart';
import 'text_summarization_animation.dart';
import 'flashcard_animation.dart';
import 'mind_map_animation.dart';
import 'quiz_animation.dart';

enum AnimationType {
  matrix,
  spaceTravel,
  neuralNetwork,
  dataProcessing,
  textSummarization,
  flashcard,
  mindMap,
  quiz
}

class AnalysisAnimationWidget extends StatelessWidget {
  final double width;
  final double height;
  final String message;
  final List<String> statusMessages;
  final AnimationType animationType;

  const AnalysisAnimationWidget({
    Key? key,
    this.width = 350,
    this.height = 300,
    required this.message,
    required this.statusMessages,
    this.animationType = AnimationType.matrix,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (animationType) {
      case AnimationType.matrix:
        return MatrixRainAnimation(
          width: width,
          height: height,
          primaryColor: AppTheme.primaryColor,
          secondaryColor: AppTheme.accentColor,
          message: message,
          statusMessages: statusMessages,
        );

      case AnimationType.spaceTravel:
        return SpaceTravelAnimation(
          width: width,
          height: height,
          primaryColor: Colors.cyanAccent,
          secondaryColor: Colors.blueAccent,
          message: message,
          statusMessages: statusMessages,
        );

      case AnimationType.neuralNetwork:
        return NeuralNetworkAnimation(
          width: width,
          height: height,
          primaryColor: Colors.purpleAccent,
          secondaryColor: Colors.deepPurple,
          message: message,
          statusMessages: statusMessages,
        );

      case AnimationType.dataProcessing:
        return DataProcessingAnimation(
          width: width,
          height: height,
          primaryColor: Colors.amber,
          secondaryColor: Colors.deepOrange,
          message: message,
          statusMessages: statusMessages,
        );

      case AnimationType.textSummarization:
        return TextSummarizationAnimation(
          width: width,
          height: height,
          primaryColor: Colors.teal,
          secondaryColor: Colors.tealAccent,
          message: message,
          statusMessages: statusMessages,
        );

      case AnimationType.flashcard:
        return FlashcardAnimation(
          width: width,
          height: height,
          primaryColor: Colors.pink,
          secondaryColor: Colors.pinkAccent,
          message: message,
          statusMessages: statusMessages,
        );

      case AnimationType.mindMap:
        return MindMapAnimation(
          width: width,
          height: height,
          primaryColor: Colors.yellow,
          secondaryColor: Colors.amber,
          message: message,
          statusMessages: statusMessages,
        );

      case AnimationType.quiz:
        return QuizAnimation(
          width: width,
          height: height,
          primaryColor: Colors.blue,
          secondaryColor: Colors.lightBlueAccent,
          message: message,
          statusMessages: statusMessages,
        );
    }
  }
}
