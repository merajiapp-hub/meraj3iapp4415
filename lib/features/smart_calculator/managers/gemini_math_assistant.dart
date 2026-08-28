import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

import '../../../config/secrets.dart';

class GeminiMathAssistant {
  static final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-pro',
    apiKey: AppSecrets.geminiApiKey,
  );

  /// Analyzes a math problem image and returns the parsed equation or solution.
  static Future<String> solveMathFromImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      
      final prompt = TextPart('''
You are an expert Math Assistant.
Analyze this image containing a mathematical problem.
1. Extract the equation or mathematical expression precisely.
2. Provide a step-by-step solution.
3. Return the final answer clearly.
Format your response in Markdown with clear sections. If it is an equation, provide the LaTeX format.
''');
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await _model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      return response.text ?? 'لم يتمكن جيميناي من فهم الصورة.';
    } catch (e) {
      return 'حدث خطأ أثناء الاتصال بالمساعد الذكي: $e';
    }
  }

  /// Answers a text-based math query.
  static Future<String> askMathQuestion(String question) async {
    try {
      final prompt = '''
You are a highly intelligent Math Assistant built into a Smart Scientific Calculator.
The user is asking: "$question"

Please provide:
1. The mathematical interpretation of what they are asking.
2. The step-by-step solution if it's a problem.
3. The final answer.
Respond in Arabic since the app is in Arabic.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? 'لم أفهم السؤال جيداً.';
    } catch (e) {
      return 'حدث خطأ: $e';
    }
  }
}
