import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── نموذج السؤال ──────────────────────────────────────────────────────────────
class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String category;
  final String? explanation;
  final QuestionDifficulty difficulty;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.category,
    this.explanation,
    this.difficulty = QuestionDifficulty.medium,
  });
}

enum QuestionDifficulty { easy, medium, hard, veryHard }

// ─── بنك الأسئلة ────────────────────────────────────────────────────────────
class QuizBank {
  static const List<Map<String, dynamic>> _rawQuestions = [
    // رياضيات
    {
      'id': 'math_01',
      'q': "ما قيمة مشتقة f(x) = x³ - 4x + 2 عند x = 2؟",
      'opts': ['8', '12', '4', '10'],
      'ans': 0,
      'cat': 'رياضيات',
      'diff': 'medium',
      'exp': "f'(x) = 3x² - 4 = 8",
    },
    {
      'id': 'math_02',
      'q': "ما مجال الدالة f(x) = √(x² - 9)؟",
      'opts': ['[-3, 3]', ']-∞,-3] ∪ [3,+∞[', 'ℝ', ']-∞, 0]'],
      'ans': 1,
      'cat': 'رياضيات',
      'diff': 'medium',
    },
    {
      'id': 'math_03',
      'q': "ما ∫(0→2) (2x+1) dx؟",
      'opts': ['6', '4', '8', '5'],
      'ans': 0,
      'cat': 'رياضيات',
      'diff': 'medium',
      'exp': '[x²+x] من 0 إلى 2 = 6',
    },
    {
      'id': 'math_04',
      'q': "إذا log₂(x)=5، ما x؟",
      'opts': ['10', '32', '16', '25'],
      'ans': 1,
      'cat': 'رياضيات',
      'diff': 'easy',
      'exp': 'x = 2⁵ = 32',
    },
    {
      'id': 'math_05',
      'q': "ما lim(x→0) sin(x)/x؟",
      'opts': ['0', '∞', '1', 'غير موجودة'],
      'ans': 2,
      'cat': 'رياضيات',
      'diff': 'medium',
    },
    {
      'id': 'math_06',
      'q': "ما مشتقة f(x) = e^(2x)·sin(x)؟",
      'opts': [
        '2e^(2x)·sin(x)',
        'e^(2x)·cos(x)',
        'e^(2x)(2sin x+cos x)',
        '2e^(2x)·cos(x)',
      ],
      'ans': 2,
      'cat': 'رياضيات',
      'diff': 'hard',
    },
    {
      'id': 'math_07',
      'q': "محدد المصفوفة |2 1; 3 4|؟",
      'opts': ['5', '11', '8', '-5'],
      'ans': 0,
      'cat': 'رياضيات',
      'diff': 'easy',
      'exp': '2×4 - 1×3 = 5',
    },
    {
      'id': 'math_08',
      'q': "حلول x² - 5x + 6 = 0؟",
      'opts': ['x=2 أو x=4', 'x=2 أو x=3', 'x=1 أو x=6', 'x=3 أو x=4'],
      'ans': 1,
      'cat': 'رياضيات',
      'diff': 'easy',
    },
    {
      'id': 'math_09',
      'q': "في مثلث قائم: وتر=5، ضلع=3. ما الضلع الثالث؟",
      'opts': ['2', '4', '√16', '6'],
      'ans': 1,
      'cat': 'رياضيات',
      'diff': 'easy',
    },
    {
      'id': 'math_10',
      'q': "ما lim(x→+∞) (3x²+2x)/(x²-1)؟",
      'opts': ['0', '2', '3', '∞'],
      'ans': 2,
      'cat': 'رياضيات',
      'diff': 'medium',
    },
    {
      'id': 'math_11',
      'q': "ما sin(30°)؟",
      'opts': ['√3/2', '√2/2', '1/2', '1'],
      'ans': 2,
      'cat': 'رياضيات',
      'diff': 'easy',
    },
    {
      'id': 'math_12',
      'q': "ما cos(60°)؟",
      'opts': ['1/2', '√3/2', '√2/2', '0'],
      'ans': 0,
      'cat': 'رياضيات',
      'diff': 'easy',
    },
    {
      'id': 'math_13',
      'q': "إذا z=2+3i فما |z|²؟",
      'opts': ['13', '5', '√13', '4'],
      'ans': 0,
      'cat': 'رياضيات',
      'diff': 'medium',
      'exp': '4+9=13',
    },
    {
      'id': 'math_14',
      'q': "ما مشتقة arctan(x)؟",
      'opts': ['1/(1+x²)', '1/√(1-x²)', '-1/(1+x²)', '√(1+x²)'],
      'ans': 0,
      'cat': 'رياضيات',
      'diff': 'hard',
    },
    {
      'id': 'math_15',
      'q': "ما الأساس e في اللوغاريتم الطبيعي؟",
      'opts': ['2', 'π', '2.718', '√2'],
      'ans': 2,
      'cat': 'رياضيات',
      'diff': 'easy',
    },
    {
      'id': 'math_16',
      'q': "أي دالة غير قابلة للتفاضل عند x=0؟",
      'opts': ['f(x)=x²', 'f(x)=|x|', 'f(x)=x³', 'f(x)=sin(x)'],
      'ans': 1,
      'cat': 'رياضيات',
      'diff': 'hard',
    },
    {
      'id': 'math_17',
      'q': "ما مستقيم التقارب الأفقي لـ f(x)=1/x؟",
      'opts': ['x=1', 'y=1', 'y=0', 'x=0'],
      'ans': 2,
      'cat': 'رياضيات',
      'diff': 'medium',
    },
    {
      'id': 'math_18',
      'q': "الحسابية vs الهندسية؟",
      'opts': [
        'الحسابية: جمع ثابت، الهندسية: ضرب ثابت',
        'الحسابية: ضرب ثابت، الهندسية: جمع ثابت',
        'متماثلتان',
        'تختلفان في الأساس فقط',
      ],
      'ans': 0,
      'cat': 'رياضيات',
      'diff': 'easy',
    },
    {
      'id': 'math_19',
      'q': "ما نهاية ∑(n=1→∞) 1/n²؟",
      'opts': ['∞', 'π²/6', '1', '2'],
      'ans': 1,
      'cat': 'رياضيات',
      'diff': 'veryHard',
      'exp': 'مسألة بازل',
    },
    {
      'id': 'math_20',
      'q': "ما الحل العام لـ y'=2y؟",
      'opts': ["y=Ce^(2x)", 'y=2x+C', "y=Ce^x", 'y=x²+C'],
      'ans': 0,
      'cat': 'رياضيات',
      'diff': 'hard',
    },

    // فيزياء
    {
      'id': 'phys_01',
      'q': "جسم تسارعه 5 م/ث² من السكون، المسافة في 4 ثوانٍ؟",
      'opts': ['20 م', '40 م', '80 م', '10 م'],
      'ans': 1,
      'cat': 'فيزياء',
      'diff': 'medium',
      'exp': 'd=½at²=40 م',
    },
    {
      'id': 'phys_02',
      'q': "جسم 2كجم بسرعة 3م/ث. طاقته الحركية؟",
      'opts': ['6 J', '9 J', '3 J', '12 J'],
      'ans': 1,
      'cat': 'فيزياء',
      'diff': 'easy',
      'exp': 'Ek=½mv²=9 J',
    },
    {
      'id': 'phys_03',
      'q': "موجة صوتية λ=0.5م، v=340م/ث. ترددها؟",
      'opts': ['170 Hz', '680 Hz', '340 Hz', '85 Hz'],
      'ans': 1,
      'cat': 'فيزياء',
      'diff': 'medium',
    },
    {
      'id': 'phys_04',
      'q': "نابض k=200N/m. شغل تمديده 10سم؟",
      'opts': ['1 J', '0.1 J', '2 J', '20 J'],
      'ans': 0,
      'cat': 'فيزياء',
      'diff': 'medium',
      'exp': 'W=½kx²=1J',
    },
    {
      'id': 'phys_05',
      'q': "وحدة المعاوقة الكهربائية؟",
      'opts': ['أمبير', 'أوم Ω', 'فولت', 'واط'],
      'ans': 1,
      'cat': 'فيزياء',
      'diff': 'easy',
    },
    {
      'id': 'phys_06',
      'q': "ثابت الزمن في دائرة RC؟",
      'opts': ['R/C', 'R+C', 'R×C', '√(RC)'],
      'ans': 2,
      'cat': 'فيزياء',
      'diff': 'medium',
      'exp': 'τ=RC',
    },
    {
      'id': 'phys_07',
      'q': "جسم يُقذف رأسياً v=20م/ث. أقصى ارتفاع (g=10)؟",
      'opts': ['10 م', '20 م', '40 م', '80 م'],
      'ans': 1,
      'cat': 'فيزياء',
      'diff': 'medium',
      'exp': 'h=v²/2g=20م',
    },
    {
      'id': 'phys_08',
      'q': "تسارع مركزي لجسم يدور r=2م بسرعة 4م/ث؟",
      'opts': ['2م/ث²', '4م/ث²', '8م/ث²', '16م/ث²'],
      'ans': 2,
      'cat': 'فيزياء',
      'diff': 'medium',
    },
    {
      'id': 'phys_09',
      'q': "سرعة الضوء في الفراغ؟",
      'opts': ['3×10⁶م/ث', '3×10⁸م/ث', '3×10¹⁰م/ث', '3×10⁵م/ث'],
      'ans': 1,
      'cat': 'فيزياء',
      'diff': 'easy',
    },
    {
      'id': 'phys_10',
      'q': "مبدأ انعدام التحديد لهايزنبرج؟",
      'opts': [
        'لا يمكن معرفة موضع وزخم جسيم بدقة في آنٍ واحد',
        'الطاقة لا تُفنى',
        'كل فعل له ردة فعل',
        'الكتلة والطاقة متكافئتان',
      ],
      'ans': 0,
      'cat': 'فيزياء',
      'diff': 'hard',
    },
    {
      'id': 'phys_11',
      'q': "ظاهرة دوبلر في الصوت؟",
      'opts': [
        'زيادة الشدة',
        'تغيُّر التردد بحركة المصدر/المستمع',
        'تقليص الموجات',
        'الانعكاس الكلي',
      ],
      'ans': 1,
      'cat': 'فيزياء',
      'diff': 'medium',
    },
    {
      'id': 'phys_12',
      'q': "تعريف الشغل الفيزيائي؟",
      'opts': [
        'القوة×الزمن',
        'الكتلة×التسارع',
        'القوة×المسافة باتجاهها',
        'الطاقة÷الزمن',
      ],
      'ans': 2,
      'cat': 'فيزياء',
      'diff': 'easy',
    },
    {
      'id': 'phys_13',
      'q': "التأثير الكهروضوئي؟",
      'opts': [
        'التفلور',
        'انبعاث إلكترونات من معدن بتأثير الضوء',
        'الانبعاث الحراري',
        'الاستحثاث',
      ],
      'ans': 1,
      'cat': 'فيزياء',
      'diff': 'medium',
    },
    {
      'id': 'phys_14',
      'q': "ثابت بلانك h؟",
      'opts': ['6.626×10⁻³⁴ J·s', '9.11×10⁻³¹ kg', '1.6×10⁻¹⁹ C', '3×10⁸ م/ث'],
      'ans': 0,
      'cat': 'فيزياء',
      'diff': 'medium',
    },

    // كيمياء
    {
      'id': 'chem_01',
      'q': "العدد الذري للنيتروجين؟",
      'opts': ['6', '7', '8', '14'],
      'ans': 1,
      'cat': 'كيمياء',
      'diff': 'easy',
    },
    {
      'id': 'chem_02',
      'q': "pH محلول [H⁺]=10⁻³M؟",
      'opts': ['3', '-3', '11', '7'],
      'ans': 0,
      'cat': 'كيمياء',
      'diff': 'easy',
      'exp': 'pH=-log[H⁺]=3',
    },
    {
      'id': 'chem_03',
      'q': "التهجين في CH₄؟",
      'opts': ['sp', 'sp²', 'sp³', 'sp³d'],
      'ans': 2,
      'cat': 'كيمياء',
      'diff': 'medium',
    },
    {
      'id': 'chem_04',
      'q': "ثابت أفوجادرو؟",
      'opts': ['6.022×10²¹', '6.022×10²³', '6.022×10²⁵', '6.022×10¹²'],
      'ans': 1,
      'cat': 'كيمياء',
      'diff': 'easy',
    },
    {
      'id': 'chem_05',
      'q': "في N₂+3H₂→2NH₃، نسبة H₂:NH₃؟",
      'opts': ['1:1', '3:2', '2:3', '1:3'],
      'ans': 1,
      'cat': 'كيمياء',
      'diff': 'medium',
    },
    {
      'id': 'chem_06',
      'q': "تفاعل الإستر مع الماء؟",
      'opts': ['الاسترة', 'التصبن', 'الأكسدة', 'الاختزال'],
      'ans': 1,
      'cat': 'كيمياء',
      'diff': 'medium',
    },
    {
      'id': 'chem_07',
      'q': "أي مادة إلكتروفيل؟",
      'opts': ['NH₃', 'OH⁻', 'BF₃', 'CH₃⁻'],
      'ans': 2,
      'cat': 'كيمياء',
      'diff': 'hard',
    },
    {
      'id': 'chem_08',
      'q': "حجم 0.5 مول غاز مثالي عند STP؟",
      'opts': ['11.2 L', '22.4 L', '5.6 L', '44.8 L'],
      'ans': 0,
      'cat': 'كيمياء',
      'diff': 'medium',
    },
    {
      'id': 'chem_09',
      'q': "نوع الرابطة في NaCl؟",
      'opts': ['تساهمية', 'تساهمية قطبية', 'أيونية', 'معدنية'],
      'ans': 2,
      'cat': 'كيمياء',
      'diff': 'easy',
    },
    {
      'id': 'chem_10',
      'q': "الرابطة الأقوى بين الذرات؟",
      'opts': ['هيدروجينية', 'فان دير فالس', 'تساهمية', 'أيونية'],
      'ans': 2,
      'cat': 'كيمياء',
      'diff': 'medium',
    },

    // علوم طبيعية
    {
      'id': 'bio_01',
      'q': "الجزيء المُخزِّن للشفرة الوراثية؟",
      'opts': ['RNA', 'DNA', 'ATP', 'ADP'],
      'ans': 1,
      'cat': 'علوم طبيعية',
      'diff': 'easy',
    },
    {
      'id': 'bio_02',
      'q': "عملية تحويل الجلوكوز لطاقة في الخلية؟",
      'opts': ['البناء الضوئي', 'الاستنساخ', 'التنفس الخلوي', 'الانقسام'],
      'ans': 2,
      'cat': 'علوم طبيعية',
      'diff': 'easy',
    },
    {
      'id': 'bio_03',
      'q': "كروموسومات الخلية الجسدية الإنسانية؟",
      'opts': ['23', '46', '48', '44'],
      'ans': 1,
      'cat': 'علوم طبيعية',
      'diff': 'easy',
    },
    {
      'id': 'bio_04',
      'q': "الهرمون المنظِّم للجلوكوز في الدم؟",
      'opts': ['الأدرينالين', 'الأنسولين', 'الثيروكسين', 'الكورتيزول'],
      'ans': 1,
      'cat': 'علوم طبيعية',
      'diff': 'easy',
    },
    {
      'id': 'bio_05',
      'q': "عضيّة تصنيع البروتين؟",
      'opts': ['النواة', 'الميتوكوندريا', 'الريبوسوم', 'الشبكة الإندوبلازمية'],
      'ans': 2,
      'cat': 'علوم طبيعية',
      'diff': 'easy',
    },
    {
      'id': 'bio_06',
      'q': "الجزيء الناقل للمعلومات الوراثية للريبوسوم؟",
      'opts': ['DNA', 'tRNA', 'mRNA', 'rRNA'],
      'ans': 2,
      'cat': 'علوم طبيعية',
      'diff': 'medium',
    },
    {
      'id': 'bio_07',
      'q': "تكاثر الأميبا؟",
      'opts': ['تكاثر جنسي', 'انشطار ثنائي', 'تبرعم', 'إخصاب'],
      'ans': 1,
      'cat': 'علوم طبيعية',
      'diff': 'easy',
    },
    {
      'id': 'bio_08',
      'q': "عملية تحويل الجلوكوز لجليكوجين في الكبد؟",
      'opts': ['تحلل السكر', 'تخليق الجليكوجين', 'الأكسدة', 'التفكك'],
      'ans': 1,
      'cat': 'علوم طبيعية',
      'diff': 'hard',
    },

    // تاريخ
    {
      'id': 'hist_01',
      'q': "تاريخ استقلال موريتانيا؟",
      'opts': [
        '28 نوفمبر 1960',
        '1 يناير 1962',
        '26 فبراير 1958',
        '20 أغسطس 1965',
      ],
      'ans': 0,
      'cat': 'تاريخ',
      'diff': 'easy',
    },
    {
      'id': 'hist_02',
      'q': "أول رئيس لموريتانيا؟",
      'opts': [
        'معاوية ولد الطايع',
        'المختار ولد داداه',
        'محمد خونا ولد هيدالة',
        'صالح ولد حنفا',
      ],
      'ans': 1,
      'cat': 'تاريخ',
      'diff': 'easy',
    },
    {
      'id': 'hist_03',
      'q': "السبب الرئيسي للحرب العالمية الأولى؟",
      'opts': [
        'اغتيال فرانز فرديناند',
        'غزو بولندا',
        'هجوم بيرل هاربر',
        'الأزمة الاقتصادية',
      ],
      'ans': 0,
      'cat': 'تاريخ',
      'diff': 'easy',
    },
    {
      'id': 'hist_04',
      'q': "سقوط الخلافة العثمانية؟",
      'opts': ['1918', '1920', '1923', '1928'],
      'ans': 2,
      'cat': 'تاريخ',
      'diff': 'medium',
    },
    {
      'id': 'hist_05',
      'q': "الاتفاقية المنهية للحرب العالمية الأولى؟",
      'opts': ['معاهدة فيرساي', 'معاهدة سيفر', 'اتفاقية فيينا', 'إعلان بلفور'],
      'ans': 0,
      'cat': 'تاريخ',
      'diff': 'medium',
    },

    // جغرافيا
    {
      'id': 'geo_01',
      'q': "أكبر محيط في العالم؟",
      'opts': ['الأطلسي', 'الهندي', 'الهادئ', 'القطبي الشمالي'],
      'ans': 2,
      'cat': 'جغرافيا',
      'diff': 'easy',
    },
    {
      'id': 'geo_02',
      'q': "أطول نهر في العالم؟",
      'opts': ['الأمازون', 'النيل', 'المسيسيبي', 'اليانغتسي'],
      'ans': 1,
      'cat': 'جغرافيا',
      'diff': 'easy',
    },
    {
      'id': 'geo_03',
      'q': "الدول الحدودية لموريتانيا؟",
      'opts': [
        'المغرب والجزائر ومالي والسنغال',
        'المغرب وتونس ومالي والنيجر',
        'الجزائر وليبيا ومالي والسنغال',
        'المغرب والجزائر والنيجر ومالي',
      ],
      'ans': 0,
      'cat': 'جغرافيا',
      'diff': 'medium',
    },
    {
      'id': 'geo_04',
      'q': "أعلى قمة في إفريقيا؟",
      'opts': ['جبل أطلس', 'كليمنجارو', 'جبل كينيا', 'جبل رووينزوري'],
      'ans': 1,
      'cat': 'جغرافيا',
      'diff': 'easy',
    },

    // لغة عربية
    {
      'id': 'arb_01',
      'q': "إعراب 'زيداً' في: رأيت زيداً؟",
      'opts': ['فاعل', 'مفعول به', 'مبتدأ', 'خبر'],
      'ans': 1,
      'cat': 'لغة عربية',
      'diff': 'easy',
    },
    {
      'id': 'arb_02',
      'q': "الفعل المجهول من 'كتب'؟",
      'opts': ['يكتب', 'كُتِبَ', 'كاتب', 'مكتوب'],
      'ans': 1,
      'cat': 'لغة عربية',
      'diff': 'easy',
    },
    {
      'id': 'arb_03',
      'q': "جمع 'كتاب'؟",
      'opts': ['كتبة', 'كُتُب', 'كِتاب', 'كتابات'],
      'ans': 1,
      'cat': 'لغة عربية',
      'diff': 'easy',
    },
    {
      'id': 'arb_04',
      'q': "إعراب 'سريعاً' في: جاء الطالب سريعاً؟",
      'opts': ['حال منصوب', 'صفة مرفوعة', 'مفعول به', 'نعت منصوب'],
      'ans': 0,
      'cat': 'لغة عربية',
      'diff': 'easy',
    },
    {
      'id': 'arb_05',
      'q': "نوع أسلوب: 'هل حضر الطلاب؟'",
      'opts': ['خبري', 'إنشائي طلبي', 'إنشائي غير طلبي', 'استفهامي تقريري'],
      'ans': 1,
      'cat': 'لغة عربية',
      'diff': 'medium',
    },
    {
      'id': 'arb_06',
      'q': "إعراب 'محمدٌ' في: محمدٌ مجتهدٌ؟",
      'opts': ['فاعل مرفوع', 'مبتدأ مرفوع', 'مفعول به', 'خبر'],
      'ans': 1,
      'cat': 'لغة عربية',
      'diff': 'easy',
    },

    // فلسفة
    {
      'id': 'phil_01',
      'q': "من قال 'أنا أفكر إذن أنا موجود'؟",
      'opts': ['أرسطو', 'أفلاطون', 'ديكارت', 'كانط'],
      'ans': 2,
      'cat': 'فلسفة',
      'diff': 'easy',
    },
    {
      'id': 'phil_02',
      'q': "المذهب القائل بأن العقل أساس المعرفة؟",
      'opts': ['التجريبية', 'العقلانية', 'البراغماتية', 'الوجودية'],
      'ans': 1,
      'cat': 'فلسفة',
      'diff': 'medium',
    },
    {
      'id': 'phil_03',
      'q': "الفيلسوف المرتبط بالديالكتيك؟",
      'opts': ['ماركس', 'هيغل', 'نيتشه', 'سارتر'],
      'ans': 1,
      'cat': 'فلسفة',
      'diff': 'hard',
    },
    {
      'id': 'phil_04',
      'q': "الوجودية ترى أن؟",
      'opts': [
        'الجوهر يسبق الوجود',
        'الوجود يسبق الجوهر',
        'لا علاقة بينهما',
        'متزامنان',
      ],
      'ans': 1,
      'cat': 'فلسفة',
      'diff': 'hard',
    },

    // فرنسية
    {
      'id': 'fren_01',
      'q': "Passé composé du verbe «aller»?",
      'opts': ['il allait', 'il est allé', 'il alla', 'il irait'],
      'ans': 1,
      'cat': 'اللغة الفرنسية',
      'diff': 'easy',
    },
    {
      'id': 'fren_02',
      'q': "Genre du mot «lune»?",
      'opts': ['masculin', 'féminin', 'neutre', 'indéterminé'],
      'ans': 1,
      'cat': 'اللغة الفرنسية',
      'diff': 'easy',
    },
    {
      'id': 'fren_03',
      'q': "Forme passive de: «Le chat mange la souris»?",
      'opts': [
        'La souris est mangée par le chat',
        'La souris mange le chat',
        'Le chat est mangé par la souris',
        'La souris a mangé le chat',
      ],
      'ans': 0,
      'cat': 'اللغة الفرنسية',
      'diff': 'medium',
    },

    // إنجليزية
    {
      'id': 'eng_01',
      'q': "Which sentence is correct?",
      'opts': [
        "She don't like coffee",
        "She doesn't likes coffee",
        "She doesn't like coffee",
        'She not like coffee',
      ],
      'ans': 2,
      'cat': 'اللغة الإنجليزية',
      'diff': 'easy',
    },
    {
      'id': 'eng_02',
      'q': "Past tense of «begin»?",
      'opts': ['began', 'begined', 'begun', 'beginned'],
      'ans': 0,
      'cat': 'اللغة الإنجليزية',
      'diff': 'easy',
    },
    {
      'id': 'eng_03',
      'q': "Synonym of «enormous»?",
      'opts': ['tiny', 'huge', 'fragile', 'quick'],
      'ans': 1,
      'cat': 'اللغة الإنجليزية',
      'diff': 'easy',
    },

    // تربية إسلامية
    {
      'id': 'islm_01',
      'q': "الركن الثالث من أركان الإسلام؟",
      'opts': ['الصلاة', 'الزكاة', 'الصوم', 'الحج'],
      'ans': 1,
      'cat': 'تربية إسلامية',
      'diff': 'easy',
    },
    {
      'id': 'islm_02',
      'q': "عدد ركعات الفجر؟",
      'opts': ['2', '3', '4', '1'],
      'ans': 0,
      'cat': 'تربية إسلامية',
      'diff': 'easy',
    },
    {
      'id': 'islm_03',
      'q': "نصاب زكاة الذهب (بالغرام تقريباً)؟",
      'opts': ['80غ', '85غ', '100غ', '70غ'],
      'ans': 1,
      'cat': 'تربية إسلامية',
      'diff': 'medium',
    },

    // تربية مدنية
    {
      'id': 'cv_01',
      'q': "النظام السياسي في موريتانيا؟",
      'opts': ['ملكية', 'جمهورية رئاسية', 'برلماني فقط', 'كونفيدرالي'],
      'ans': 1,
      'cat': 'تربية مدنية',
      'diff': 'easy',
    },

    // ثقافة عامة
    {
      'id': 'gen_01',
      'q': "عاصمة موريتانيا؟",
      'opts': ['نواذيبو', 'روصو', 'نواكشوط', 'كيفة'],
      'ans': 2,
      'cat': 'ثقافة عامة',
      'diff': 'easy',
    },
    {
      'id': 'gen_02',
      'q': "عدد ولايات موريتانيا؟",
      'opts': ['13', '15', '12', '16'],
      'ans': 1,
      'cat': 'ثقافة عامة',
      'diff': 'medium',
    },
    {
      'id': 'gen_03',
      'q': "أكبر خام في موريتانيا احتياطياً؟",
      'opts': ['الفوسفات', 'الذهب', 'الحديد', 'البترول'],
      'ans': 2,
      'cat': 'ثقافة عامة',
      'diff': 'medium',
    },
    {
      'id': 'gen_04',
      'q': "على أي محيط تطل موريتانيا؟",
      'opts': ['الهندي', 'الهادئ', 'الأطلسي', 'البحر المتوسط'],
      'ans': 2,
      'cat': 'ثقافة عامة',
      'diff': 'easy',
    },
    {
      'id': 'gen_05',
      'q': "كاتب رواية البؤساء؟",
      'opts': ['فيكتور هوغو', 'فلوبير', 'بلزاك', 'ديكنز'],
      'ans': 0,
      'cat': 'ثقافة عامة',
      'diff': 'easy',
    },
    {
      'id': 'gen_06',
      'q': "مكتشف نظرية النسبية العامة؟",
      'opts': ['نيوتن', 'ماكسويل', 'بور', 'أينشتاين'],
      'ans': 3,
      'cat': 'ثقافة عامة',
      'diff': 'easy',
    },
    {
      'id': 'gen_07',
      'q': "أكبر صحراء في العالم مساحةً؟",
      'opts': ['جوبي', 'الصحراء الكبرى', 'أنتاركتيكا', 'الصحراء العربية'],
      'ans': 2,
      'cat': 'ثقافة عامة',
      'diff': 'medium',
      'exp': 'صحراء أنتاركتيكا هي الأكبر',
    },

    // أسئلة إضافية متنوعة
    {
      'id': 'add_01',
      'q': "أكبر قارة في العالم مساحةً والسكان؟",
      'opts': ['إفريقيا', 'آسيا', 'أوروبا', 'أمريكا الشمالية'],
      'ans': 1,
      'cat': 'جغرافيا',
      'diff': 'easy',
    },
    {
      'id': 'add_02',
      'q': "عاصمة الإمبراطورية المرابطية التي تأسست في موريتانيا؟",
      'opts': ['مراكش', 'أوداغست', 'أزوكي', 'ولاتة'],
      'ans': 2,
      'cat': 'تاريخ',
      'diff': 'medium',
    },
    {
      'id': 'add_03',
      'q': "ما هو العنصر الكيميائي الذي رمزه 'O'؟",
      'opts': ['الذهب', 'الأكسجين', 'الفضة', 'الكربون'],
      'ans': 1,
      'cat': 'كيمياء',
      'diff': 'easy',
    },
    {
      'id': 'add_04',
      'q': "من هو مؤسس علم الجبر؟",
      'opts': ['ابن سينا', 'الخوارزمي', 'ابن الهيثم', 'جابر بن حيان'],
      'ans': 1,
      'cat': 'رياضيات',
      'diff': 'medium',
    },
    {
      'id': 'add_05',
      'q': "أي كوكب يعرف بالكوكب الأحمر؟",
      'opts': ['المشتري', 'الزهرة', 'المريخ', 'زحل'],
      'ans': 2,
      'cat': 'علوم طبيعية',
      'diff': 'easy',
    },
    {
      'id': 'add_06',
      'q': "ما هي أطول سورة في القرآن الكريم؟",
      'opts': ['سورة آل عمران', 'سورة النساء', 'سورة البقرة', 'سورة المائدة'],
      'ans': 2,
      'cat': 'تربية إسلامية',
      'diff': 'easy',
    },
    {
      'id': 'add_07',
      'q': "متى اندلعت الحرب العالمية الثانية؟",
      'opts': ['1939', '1945', '1914', '1935'],
      'ans': 0,
      'cat': 'تاريخ',
      'diff': 'easy',
    },
    {
      'id': 'add_08',
      'q': "أين تقع أطول سلسلة جبلية في العالم 'الأنديز'؟",
      'opts': ['أمريكا الشمالية', 'أمريكا الجنوبية', 'آسيا', 'أوروبا'],
      'ans': 1,
      'cat': 'جغرافيا',
      'diff': 'medium',
    },
    {
      'id': 'add_09',
      'q': "ما هو لون الذهب في حالته النقية؟",
      'opts': ['أصفر', 'أبيض', 'أحمر', 'شفاف'],
      'ans': 0,
      'cat': 'كيمياء',
      'diff': 'easy',
    },
    {
      'id': 'add_10',
      'q': "ماذا يسمى المثلث الذي جميع أضلاعه مختلفة؟",
      'opts': [
        'متساوي الأضلاع',
        'متساوي الساقين',
        'مختلف الأضلاع',
        'قائم الزاوية',
      ],
      'ans': 2,
      'cat': 'رياضيات',
      'diff': 'easy',
    },
  ];

  static List<QuizQuestion> get allQuestions => _rawQuestions.map((q) {
    QuestionDifficulty diff;
    switch (q['diff'] as String) {
      case 'easy':
        diff = QuestionDifficulty.easy;
        break;
      case 'hard':
        diff = QuestionDifficulty.hard;
        break;
      case 'veryHard':
        diff = QuestionDifficulty.veryHard;
        break;
      default:
        diff = QuestionDifficulty.medium;
    }
    return QuizQuestion(
      id: q['id'] as String,
      question: q['q'] as String,
      options: List<String>.from(q['opts'] as List),
      correctIndex: q['ans'] as int,
      category: q['cat'] as String,
      explanation: q.containsKey('exp') ? q['exp'] as String : null,
      difficulty: diff,
    );
  }).toList();
}

// ─── Provider ─────────────────────────────────────────────────────────────────
class QuizProvider extends ChangeNotifier {
  int _xp = 0;
  int _streak = 0;
  DateTime? _lastQuizDate;
  List<QuizQuestion> _currentQuiz = [];
  final Map<String, bool> _answeredQuestions = {};
  final List<String> _usedQuestionIds = [];

  int get xp => _xp;
  int get streak => _streak;
  List<QuizQuestion> get dailyQuestions => _currentQuiz;
  int get totalQuestions => QuizBank.allQuestions.length;
  int get correctCount => _answeredQuestions.values.where((v) => v).length;
  int get wrongCount => _answeredQuestions.values.where((v) => !v).length;

  QuizProvider() {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _xp = prefs.getInt('quiz_xp') ?? 0;
    _streak = prefs.getInt('quiz_streak') ?? 0;
    final lastDateStr = prefs.getString('last_quiz_date');
    if (lastDateStr != null) {
      _lastQuizDate = DateTime.parse(lastDateStr);
    }
    final usedIds = prefs.getStringList('used_question_ids') ?? [];
    _usedQuestionIds.addAll(usedIds);
    generateNewQuiz();
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quiz_xp', _xp);
    await prefs.setInt('quiz_streak', _streak);
    if (_lastQuizDate != null) {
      await prefs.setString('last_quiz_date', _lastQuizDate!.toIso8601String());
    }
    await prefs.setStringList('used_question_ids', _usedQuestionIds);
  }

  void generateNewQuiz({int count = 15}) {
    final all = QuizBank.allQuestions;
    var available = all.where((q) => !_usedQuestionIds.contains(q.id)).toList();

    if (available.length < count) {
      _usedQuestionIds.clear();
      available = List.from(all);
    }

    available.shuffle(Random());
    _currentQuiz = available.take(count).map(_shuffleOptions).toList();
    _answeredQuestions.clear();

    for (final q in _currentQuiz) {
      _usedQuestionIds.add(q.id);
    }
    _saveProgress();
    notifyListeners();
  }

  QuizQuestion _shuffleOptions(QuizQuestion q) {
    final correctAnswer = q.options[q.correctIndex];
    final shuffled = List<String>.from(q.options)..shuffle(Random());
    return QuizQuestion(
      id: q.id,
      question: q.question,
      options: shuffled,
      correctIndex: shuffled.indexOf(correctAnswer),
      category: q.category,
      explanation: q.explanation,
      difficulty: q.difficulty,
    );
  }

  void answerQuestion(String id, bool isCorrect) {
    if (_answeredQuestions.containsKey(id)) return;
    _answeredQuestions[id] = isCorrect;
    if (isCorrect) {
      _xp += 10;
      _updateStreak();
    }
    _saveProgress();
    notifyListeners();
  }

  void _updateStreak() {
    final now = DateTime.now();
    if (_lastQuizDate == null) {
      _streak = 1;
    } else {
      final diff = now.difference(_lastQuizDate!).inDays;
      if (diff == 1) {
        _streak++;
      } else if (diff > 1) {
        _streak = 1;
      }
    }
    _lastQuizDate = now;
  }
}
