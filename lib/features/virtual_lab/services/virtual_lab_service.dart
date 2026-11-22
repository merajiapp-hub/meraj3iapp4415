import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/experiment_model.dart';
import '../models/lab_progress_model.dart';

class VirtualLabService {
  static final VirtualLabService _instance = VirtualLabService._internal();
  factory VirtualLabService() => _instance;
  VirtualLabService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _prefProgressKey = 'virtual_lab_user_progress_v1';

  // ═══════════════════════════════════════════════════════════════════════════
  // التجارب الافتراضية المدمجة في التطبيق (متاحة أوفلاين دون إنترنت)
  // ═══════════════════════════════════════════════════════════════════════════
  static final List<ExperimentModel> defaultExperiments = [
    // التجربة 1: التفاعل الكيميائي وانحفاظ الكتلة
    const ExperimentModel(
      id: 'chem_mass_conservation',
      title: 'التفاعل الكيميائي وانحفاظ الكتلة',
      titleFr: 'Réaction chimique et conservation de la masse',
      subject: 'chemistry',
      gradeLevels: ['3AS', '4AS', 'Terminale', 'BAC D', 'BAC C'],
      description:
          'محاكاة تفاعلية ثلاثية الأبعاد متقدمة للتحقق من قانون لافوازييه لانحفاظ الكتلة في الأنظمة المغلقة والمفتوحة عبر ميزان إلكتروني فائق الدقة وتفاعل حمض الخل مع بيكربونات الصوديوم.',
      chemicalFormula: 'CH₃COOH + NaHCO₃ → CH₃COONa + H₂O + CO₂↑',
      durationMinutes: 15,
      difficulty: 'medium',
      isPro: false,
      isPublished: true,
      htmlAssetPath: 'assets/labs/chemistry/mass_conservation/index.html',
      objectives: [
        'التحقق التجريبي الدقيق من انحفاظ الكتلة خلال تحول كيميائي في نظام مغلق.',
        'مقارنة كتلة المتفاعلات قبل التفاعل بكتلة النواتج بعد التفاعل.',
        'ملاحظة انطلاق غاز ثاني أكسيد الكربون وفوران المحلول.',
        'تفسير نقصان الكتلة المسجلة عند فتح السدادة بهروب الغاز إلى الوسط الخارجي.',
      ],
      safetyTips: [
        'ارتداء نظارات السلامة ومعطف المختبر أثناء التعامل مع المحاليل الحمضية.',
        'التأكد من إحكام إغلاق السدادة المطاطية قبل بدء التفاعل لضمان عدم تسرب الغاز.',
        'الحذر من زيادة الضغط داخل الحوجلة أثناء التفاعلات السريعة المنتجة للغازات.',
      ],
      equipment: [
        'ميزان رقمي حساس بدقة 0.01 g (Balance électronique)',
        'حوجلة زجاجية إرلنماير (Fiole Erlenmeyer 250 mL)',
        'أنبوب اختبار صغير داخلي (Tube à essai)',
        'سدادة مطاطية مانعة لتسرب الغازات (Bouchon hermétique)',
        'محلول حمض الخل المخفف (Vinaigre / CH₃COOH)',
        'مسحوق بيكربونات الصوديوم النقي (Bicarbonate de soude / NaHCO₃)',
      ],
      steps: [
        ExperimentStep(
          number: 1,
          title: 'القياس الابتدائي في نظام مغلق',
          instruction:
              'ضع الحوجلة المحتوية على حمض الخل وأنبوب بيكربونات الصوديوم مع السدادة على الميزان، وسجل الكتلة الابتدائية m₁ = 152.40 g.',
        ),
        ExperimentStep(
          number: 2,
          title: 'إطلاق التفاعل الكيميائي',
          instruction:
              'اضغط على «مزج المتفاعلات» لإمالة الأنبوب ومزج المسحوق مع الحمض. راقب فوران المحلول وتشكل فقاعات غاز CO₂.',
        ),
        ExperimentStep(
          number: 3,
          title: 'مراقبة ثبات الكتلة',
          instruction:
              'لاحظ شاشة الميزان بعد انتهاء الفوران؛ تظل الكتلة ثابتة m₂ = 152.40 g تماماً؛ لأن النظام مغلق بالكامل.',
        ),
        ExperimentStep(
          number: 4,
          title: 'فتح السدادة وانطلاق الغاز',
          instruction:
              'اضغط على «فتح السدادة» للسماح لغاز ثاني أكسيد الكربون بالخروج. لاحظ انخفاض الكتلة إلى 150.20 g وحساب كتلة الغاز المنطلق.',
        ),
      ],
      quizQuestions: [
        QuizQuestion(
          id: 'q1_mass',
          question: 'خلال تفاعل كيميائي في دورق مغلق بإحكام، ماذا يحدث للكتلة الكلية للنظام؟',
          options: [
            'تنقص بسبب استهلاك المواد المتفاعلة',
            'تبقى ثابتة وتساوي كتلة المواد الناتجة',
            'تزداد بسبب تشكل غاز جديد',
            'تتضاعف نتيجة التحول الكيميائي',
          ],
          correctIndex: 1,
          explanation:
              'وفقاً لقانون لافوازييه، في أي نظام مغلق، الكتلة الكلية للمتفاعلات تساوي تماماً الكتلة الكلية للنواتج: m(réactifs) = m(produits).',
        ),
        QuizQuestion(
          id: 'q2_mass',
          question: 'ما هو التفسير العلمي لانخفاض قراءة الميزان من 152.40 g إلى 150.20 g بعد فتح السدادة؟',
          options: [
            'تبخر حمض الخل بالكامل',
            'انطلاق وتسرب غاز ثنائي أكسيد الكربون CO₂ إلى الهواء الخارجي',
            'تلف في حساسية الميزان الرقمي',
            'تكاثف بخار الماء على جدار الدورق',
          ],
          correctIndex: 1,
          explanation:
              'عند فتح السدادة، أصبح النظام مفتوحاً فغادر غاز ثاني أكسيد الكربون الناتج الحوجلة، وتساوي كتلته: Δm = 152.40 - 150.20 = 2.20 g.',
        ),
        QuizQuestion(
          id: 'q3_mass',
          question: 'من هو العالم الفرنسي صاحب المقولة الشهيرة: «لا شيء يضيع، لا شيء يُخلق، كل شيء يتحول»؟',
          options: [
            'أنطوان لافوازييه (Antoine Lavoisier)',
            'لويس باستور (Louis Pasteur)',
            'ماري كوري (Marie Curie)',
            'ديمتري مندلييف (Dmitri Mendeleïev)',
          ],
          correctIndex: 0,
          explanation:
              'العالم الفرنسي أنطوان لافوازييه هو مؤسس الكيمياء الحديثة ومكتشف قانون انحفاظ الكتلة في التفاعلات الكيميائية.',
        ),
      ],
      conclusion:
          '«Rien ne se perd, rien ne se crée, tout se transforme»\nخلال تفاعل كيميائي في نظام مغلق، الكتلة محفوظة دائماً: مجموع كتل المتفاعلات يساوي مجموع كتل النواتج. عند فتح النظام، فإن الغازات الناتجة تفلت مسببة نقصاً ظاهرياً في الكتلة.',
    ),

    // التجربة 2: تحضير محلول: الذوبان والتخفيف
    const ExperimentModel(
      id: 'chem_solution_dilution',
      title: 'تحضير محلول: الذوبان والتخفيف',
      titleFr: "Préparation d'une solution : dissolution et dilution",
      subject: 'chemistry',
      gradeLevels: ['4AS', 'Terminale', 'BAC D', 'BAC C'],
      description:
          'تجربة تفاعلية ثلاثية الأبعاد لإتقان البروتوكول التجريبي لتحضير محلول كبريتات النحاس المائي بالتركيز المطلوب، تليها عملية التخفيف الدقيق بالماء المقطر مع التحقق من انحفاظ كمية المادة.',
      chemicalFormula: 'C₀ = n / V₀ = m / (M · V₀)  |  C₀ · V₀ = C₁ · V₁',
      durationMinutes: 20,
      difficulty: 'hard',
      isPro: true,
      isPublished: true,
      htmlAssetPath: 'assets/labs/chemistry/solution_dilution/index.html',
      objectives: [
        'إتقان خطوات البروتوكول المخبري لتحضير محلول مائي متجانس انطلاقاً من مادة صلبة.',
        'حساب الكتلة الواجب وزنها لتحضير تركيز مولي معين: m = C · V · M.',
        'تنفيذ عملية التخفيف بالماصة والحوجلة العيارية مع تحديد معامل التخفيف F.',
        'استيعاب مبدأ انحفاظ كمية المادة n₀ = n₁ أثناء التخفيف وتفسير تدرج شدة اللون.',
      ],
      safetyTips: [
        'كبريتات النحاس ضارة بالبيئة المائية وتسبب تهيجاً للجلد؛ يجب استخدام القفازات.',
        'عدم سحب المحاليل الكيميائية بالفم إطلاقاً، واستخدام إجاصة السحب (Poire aspirante) مع الماصة.',
        'إتمام الحجم دائماً بالماء المقطر حتى استواء أسفل التقعر مع الخط العياري عند مستوى العين.',
      ],
      equipment: [
        'حوجلة عيارية سعة 100 mL مع سدادة (Fiole jaugée 100 mL)',
        'حوجلة عيارية ثانية سعة 100 mL لإجراء التخفيف',
        'ميزان إلكتروني دقيق وزجاجة ساعة (Verre de montre)',
        'ملعقة مخبرية نظيفة (Spatule)',
        'قمع زجاجي وقضيب تحريك (Entonnoir & Agitateur)',
        'ماصة مدرجة سعة 20 mL مع إجاصة مطاطية',
        'قارورة غسيل ماء مقطر (Pissette d\'eau distillée)',
        'بلورات كبريتات النحاس المائية الزرقاء (CuSO₄·5H₂O)',
      ],
      steps: [
        ExperimentStep(
          number: 1,
          title: 'وزن المذاب وحساب الكتلة',
          instruction:
              'حدد كتلة كبريتات النحاس m عبر شريط التمرير؛ تلاحظ التحديث الفوري لكمية المادة n والتركيز C₀.',
        ),
        ExperimentStep(
          number: 2,
          title: 'الإذابة والتحريك',
          instruction:
              'اضغط على «إذابة وتحريك» لإذابة البلورات في الماء؛ يظهر لون أزرق مميز تزداد شدته مع زيادة التركيز.',
        ),
        ExperimentStep(
          number: 3,
          title: 'إتمام الحجم حتى خط العيار',
          instruction:
              'أضف الماء المقطر حتى يصل السائل إلى الخط العياري للحوجلة (100 mL) لتثبيت الحجم النهائي V₀ بدقة.',
        ),
        ExperimentStep(
          number: 4,
          title: 'إجراء التخفيف (Dilution F=5)',
          instruction:
              'اضغط على «إجراء التخفيف» لأخذ عينة V₀/5 ونقلها إلى الحوجلة الثانية وتمديدها بالماء المقطر للحصول على المحلول S₁.',
        ),
      ],
      quizQuestions: [
        QuizQuestion(
          id: 'q1_dil',
          question: 'ما هي الصيغة الصحيحة لحساب الكتلة m اللازمة لتحضير حجم V من محلول بتركيز مولي C وكتلة مولية M؟',
          options: [
            'm = C · V · M',
            'm = (C · M) / V',
            'm = (V · M) / C',
            'm = C / (V · M)',
          ],
          correctIndex: 0,
          explanation: 'بما أن n = C · V و n = m / M، فإن m = n · M = C · V · M.',
        ),
        QuizQuestion(
          id: 'q2_dil',
          question: 'عند تخفيف محلول أم S₀ ذو تركيز C₀ خمس مرات (F = 5)، ما هو تركيز المحلول المخفف S₁؟',
          options: [
            'C₁ = 5 · C₀',
            'C₁ = C₀ / 5',
            'C₁ = C₀ - 5',
            'C₁ = C₀ + 5',
          ],
          correctIndex: 1,
          explanation: 'معامل التخفيف F = C₀ / C₁ = 5، إذن C₁ = C₀ / 5. التركيز ينخفض بمقدار 5 مرات.',
        ),
        QuizQuestion(
          id: 'q3_dil',
          question: 'ما هو المقدار الفيزيائي الذي يبقى محفوظاً وثابتاً أثناء عملية التخفيف بالماء المقطر؟',
          options: [
            'التركيز المولي للمحلول (C)',
            'حجم المحلول الكلي (V)',
            'كمية مادة المذاب (n = C · V)',
            'شدة لون المحلول وعتامته',
          ],
          correctIndex: 2,
          explanation:
              'إضافة الماء المقطر لا يغير من عدد جسيمات المذاب المذابة، وبالتالي تبقى كمية المادة محفوظة: n₀ = n₁ أو C₀ · V₀ = C₁ · V₁.',
        ),
      ],
      conclusion:
          'تحضير المحاليل بالذوبان يعتمد على العلاقة m = C · V · M، بينما التخفيف يعتمد على انحفاظ كمية مادة المذاب n₀ = n₁ (أي C₀ · V₀ = C₁ · V₁). يؤدي التخفيف إلى انخفاض التركيز وتناقص شدة لون المحلول بمقدار معامل التخفيف F.',
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // استرجاع قائمة التجارب (المدمجة + المنشورة من لوحة الإدارة في Firestore)
  // ═══════════════════════════════════════════════════════════════════════════
  Stream<List<ExperimentModel>> streamExperiments() {
    return _firestore
        .collection('virtual_lab_experiments')
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return defaultExperiments;
          }
          final customList = snapshot.docs.map((doc) {
            return ExperimentModel.fromJson(doc.data(), docId: doc.id);
          }).toList();

          // دمج التجارب مع التأكد من عدم تكرار المعرفات
          final map = <String, ExperimentModel>{};
          for (final def in defaultExperiments) {
            map[def.id] = def;
          }
          for (final c in customList) {
            map[c.id] = c;
          }
          return map.values.toList();
        });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // حفظ ومتابعة تقدم الطالب (Progress Tracking)
  // ═══════════════════════════════════════════════════════════════════════════
  Future<LabProgress> getProgress(String? userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localStr = prefs.getString(_prefProgressKey);
      if (localStr != null) {
        final decoded = json.decode(localStr) as Map<String, dynamic>;
        return LabProgress.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('[VirtualLabService] getProgress error: $e');
    }
    return const LabProgress();
  }

  Future<void> saveExperimentCompleted({
    required String? userId,
    required String experimentId,
    int? quizScore,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await getProgress(userId);

      final completed = Set<String>.from(current.completedExperiments)..add(experimentId);
      final scores = Map<String, int>.from(current.quizScores);
      if (quizScore != null) {
        scores[experimentId] = quizScore;
      }

      final updated = LabProgress(
        completedExperiments: completed,
        quizScores: scores,
        totalMinutesSpent: current.totalMinutesSpent + 15,
      );

      await prefs.setString(_prefProgressKey, json.encode(updated.toJson()));

      // مزامنة مع Firestore لحساب المستخدم إن كان مسجلاً
      if (userId != null && userId.isNotEmpty) {
        await _firestore.collection('users').doc(userId).set({
          'labProgress': updated.toJson(),
          'lastLabActivity': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('[VirtualLabService] saveProgress error: $e');
    }
  }
}
