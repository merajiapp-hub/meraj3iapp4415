import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

import '../../../config/secrets.dart';

class GeminiMathAssistant {
  static final GenerativeModel _model = GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: AppSecrets.geminiApiKey,
    systemInstruction: Content.system(
      '''أنت مساعد رياضي ذكي متخصص مدمج في تطبيق حاسبة علمية.
مهمتك:
1. حل المعادلات الجبرية والتفاضلية والتكاملية خطوة بخطوة.
2. دعم العمليات: الكسور، الجذور، القوى، المثلثات، المتتاليات، الحدود، المشتقات، التكاملات.
3. الشرح دائمًا بالعربية مع المعادلات بالرموز والأرقام الإنجليزية.
4. البادئات المطلوبة في الإجابة:
   - "📌 " للمعطيات والتعريف
   - "▶ " لكل خطوة حسابية
   - "✅ " للنتيجة النهائية فقط
   - "📝 " للقاعدة أو الملاحظة النظرية
5. كن دقيقًا ومختصرًا. لا تضف كلامًا غير ضروري.''',
    ),
  );

  /// Analyzes a math problem image and returns the parsed equation or solution.
  static Future<String> solveMathFromImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();

      final prompt = TextPart(
          'استخرج المعادلة الرياضية من هذه الصورة بدقة، ثم حلها خطوة بخطوة.');
      final imagePart = DataPart('image/jpeg', imageBytes);

      final response = await _model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      return response.text ?? 'لم يتمكن المساعد من فهم الصورة.';
    } catch (e) {
      return 'حدث خطأ أثناء الاتصال بالمساعد الذكي: $e';
    }
  }

  /// Answers a text-based math query.
  static Future<String> askMathQuestion(String question) async {
    try {
      final response = await _model.generateContent([Content.text(question)]);
      return response.text ?? 'لم أفهم السؤال جيداً.';
    } catch (e) {
      return 'حدث خطأ: $e';
    }
  }
}
