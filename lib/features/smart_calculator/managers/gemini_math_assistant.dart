import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

import '../../../config/secrets.dart';

class GeminiMathAssistant {
  static final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: AppSecrets.geminiApiKey,
    systemInstruction: Content.system(
      '''أنت مساعد رياضي ذكي متخصص مدمج في تطبيق حاسبة علمية.
مهمتك:
1. حل المعادلات الجبرية والتفاضلية والتكاملية خطوة بخطوة.
2. دعم العمليات: الكسور، الجذور، القوى، المثلثات، المتتاليات، الحدود، المشتقات، التكاملات، والمعادلات الطويلة والمعقدة.
3. قراءة المسائل الرياضية بدقة عالية سواء كانت مطبوعة أو مكتوبة بخط اليد.
4. الشرح دائمًا بالعربية مع المعادلات بالرموز والأرقام الإنجليزية.
5. البادئات المطلوبة في الإجابة:
   - "📌 " للمعطيات والتعريف
   - "▶ " لكل خطوة حسابية
   - "✅ " للنتيجة النهائية فقط
   - "📝 " للقاعدة أو الملاحظة النظرية
6. كن دقيقًا ومختصرًا. لا تضف كلامًا غير ضروري.''',
    ),
  );

  /// Analyzes a math problem image and returns the parsed equation or solution.
  static Future<String> solveMathFromImage(File imageFile, {int retries = 2}) async {
    for (int i = 0; i <= retries; i++) {
      try {
        final imageBytes = await imageFile.readAsBytes();

        final prompt = TextPart(
            'استخرج المعادلة أو المسألة الرياضية من هذه الصورة بدقة (سواء كانت مطبوعة أو مكتوبة بخط اليد)، ثم قم بحلها بالتفصيل وخطوة بخطوة. تأكد من التعامل مع الكسور والجذور والأسس بشكل صحيح.');
        final imagePart = DataPart('image/jpeg', imageBytes);

        final response = await _model.generateContent([
          Content.multi([prompt, imagePart])
        ]);

        if (response.text != null && response.text!.isNotEmpty) {
           return response.text!;
        }
      } catch (e) {
        if (i == retries) {
           return 'عذراً، لم أتمكن من معالجة الصورة حالياً بسبب ضغط على الشبكة. يرجى التأكد من اتصالك والمحاولة مرة أخرى.';
        }
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }
    return 'عذراً، لم يتمكن المساعد من فهم الصورة. يرجى التأكد من وضوحها.';
  }

  /// Answers a text-based math query.
  static Future<String> askMathQuestion(String question, {int retries = 2}) async {
    for (int i = 0; i <= retries; i++) {
      try {
        final response = await _model.generateContent([Content.text(question)]);
        if (response.text != null && response.text!.isNotEmpty) {
           return response.text!;
        }
      } catch (e) {
        if (i == retries) {
           return 'عذراً، حدث خطأ أثناء الاتصال بالمساعد الذكي. يرجى المحاولة لاحقاً.';
        }
        await Future.delayed(const Duration(milliseconds: 800));
      }
    }
    return 'لم أفهم السؤال جيداً.';
  }
}
