import 'quiz_models.dart';

class QuizBank {
  static const List<Map<String, dynamic>> _rawQuestions = [
    // الرياضيات (Mathématiques)
    {
      'id': 'math_01',
      'q': "Quelle est la valeur de la dérivée de f(x) = x³ - 4x + 2 à x = 2 ?",
      'opts': ['8', '12', '4', '10'],
      'ans': 0,
      'cat': 'رياضيات',
      'diff': 'medium',
      'exp': "f'(x) = 3x² - 4 = 8",
    },
    {
      'id': 'math_02',
      'q': "Quel est le domaine de définition de f(x) = √(x² - 9) ?",
      'opts': ['[-3, 3]', ']-∞,-3] ∪ [3,+∞[', 'ℝ', ']-∞, 0]'],
      'ans': 1,
      'cat': 'رياضيات',
      'diff': 'medium',
    },
    {
      'id': 'math_03',
      'q': "Que vaut ∫(0→2) (2x+1) dx ?",
      'opts': ['6', '4', '8', '5'],
      'ans': 0,
      'cat': 'رياضيات',
      'diff': 'medium',
      'exp': '[x²+x] de 0 à 2 = 6',
    },
    {
      'id': 'math_04',
      'q': "Si log₂(x)=5, que vaut x ?",
      'opts': ['10', '32', '16', '25'],
      'ans': 1,
      'cat': 'رياضيات',
      'diff': 'easy',
      'exp': 'x = 2⁵ = 32',
    },
    {
      'id': 'math_05',
      'q': "Que vaut lim(x→0) sin(x)/x ?",
      'opts': ['0', '∞', '1', 'N\'existe pas'],
      'ans': 2,
      'cat': 'رياضيات',
      'diff': 'medium',
    },
    {
      'id': 'math_06',
      'q': "Quelle est la dérivée de f(x) = e^(2x)·sin(x) ?",
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
      'q': "Le déterminant de la matrice |2 1; 3 4| ?",
      'opts': ['5', '11', '8', '-5'],
      'ans': 0,
      'cat': 'رياضيات',
      'diff': 'easy',
      'exp': '2×4 - 1×3 = 5',
    },
    {
      'id': 'math_08',
      'q': "Les solutions de x² - 5x + 6 = 0 ?",
      'opts': ['x=2 ou x=4', 'x=2 ou x=3', 'x=1 ou x=6', 'x=3 ou x=4'],
      'ans': 1,
      'cat': 'رياضيات',
      'diff': 'easy',
    },
    {
      'id': 'math_09',
      'q': "Dans un triangle rectangle: hypoténuse=5, côté=3. Quel est l'autre côté?",
      'opts': ['2', '4', '√16', '6'],
      'ans': 1,
      'cat': 'رياضيات',
      'diff': 'easy',
    },
    {
      'id': 'math_10',
      'q': "Que vaut lim(x→+∞) (3x²+2x)/(x²-1) ?",
      'opts': ['0', '2', '3', '∞'],
      'ans': 2,
      'cat': 'رياضيات',
      'diff': 'medium',
    },
    {
      'id': 'math_11',
      'q': "Que vaut lim(n→∞) (1 + 1/n)ⁿ ?",
      'opts': ['1', '∞', 'e', '0'],
      'ans': 2,
      'cat': 'رياضيات',
      'diff': 'hard',
    },
    {
      'id': 'math_12',
      'q': "Si z = 1 + i, que vaut z⁴ ?",
      'opts': ['-4', '4', '-4i', '4i'],
      'ans': 0,
      'cat': 'رياضيات',
      'diff': 'veryHard',
      'exp': 'z = √2(cos(π/4) + i sin(π/4)), z⁴ = 4(cos(π) + i sin(π)) = -4',
    },

    // الفيزياء (Physique)
    {
      'id': 'phys_01',
      'q': "Un objet accélère de 5 m/s² depuis le repos. Quelle est la distance parcourue en 4 s ?",
      'opts': ['20 m', '40 m', '80 m', '10 m'],
      'ans': 1,
      'cat': 'فيزياء',
      'diff': 'medium',
      'exp': 'd=½at²=40 m',
    },
    {
      'id': 'phys_02',
      'q': "Un objet de 2 kg à une vitesse de 3 m/s. Son énergie cinétique ?",
      'opts': ['6 J', '9 J', '3 J', '12 J'],
      'ans': 1,
      'cat': 'فيزياء',
      'diff': 'easy',
      'exp': 'Ek=½mv²=9 J',
    },
    {
      'id': 'phys_03',
      'q': "Onde sonore λ=0.5m, v=340m/s. Sa fréquence ?",
      'opts': ['170 Hz', '680 Hz', '340 Hz', '85 Hz'],
      'ans': 1,
      'cat': 'فيزياء',
      'diff': 'medium',
    },
    {
      'id': 'phys_04',
      'q': "Ressort k=200N/m. Travail pour un étirement de 10cm ?",
      'opts': ['1 J', '0.1 J', '2 J', '20 J'],
      'ans': 0,
      'cat': 'فيزياء',
      'diff': 'medium',
      'exp': 'W=½kx²=1J',
    },
    {
      'id': 'phys_05',
      'q': "Unité de l'impédance électrique ?",
      'opts': ['Ampère', 'Ohm Ω', 'Volt', 'Watt'],
      'ans': 1,
      'cat': 'فيزياء',
      'diff': 'easy',
    },
    {
      'id': 'phys_06',
      'q': "Loi de Coulomb : Si on double la distance, la force est...",
      'opts': ['Divisée par 2', 'Divisée par 4', 'Multipliée par 2', 'Inchangée'],
      'ans': 1,
      'cat': 'فيزياء',
      'diff': 'hard',
      'exp': 'F ∝ 1/r²',
    },
    {
      'id': 'phys_07',
      'q': "Dans un circuit RC, que vaut la constante de temps ?",
      'opts': ['R/C', 'C/R', 'RC', '1/(RC)'],
      'ans': 2,
      'cat': 'فيزياء',
      'diff': 'medium',
    },
    {
      'id': 'phys_08',
      'q': "Une particule α est un noyau de...",
      'opts': ['Hydrogène', 'Hélium', 'Carbone', 'Uranium'],
      'ans': 1,
      'cat': 'فيزياء',
      'diff': 'medium',
    },

    // الكيمياء (Chimie / Sciences)
    {
      'id': 'chem_01',
      'q': "Quel est le pH d'une solution neutre à 25°C ?",
      'opts': ['0', '7', '14', '1'],
      'ans': 1,
      'cat': 'العلوم',
      'diff': 'easy',
    },
    {
      'id': 'chem_02',
      'q': "La formule chimique du sel de table ?",
      'opts': ['NaCl', 'H2O', 'CO2', 'HCl'],
      'ans': 0,
      'cat': 'العلوم',
      'diff': 'easy',
    },
    {
      'id': 'chem_03',
      'q': "L'oxydation est une...",
      'opts': ['Perte d\'électrons', 'Gain d\'électrons', 'Perte de protons', 'Gain de neutrons'],
      'ans': 0,
      'cat': 'العلوم',
      'diff': 'medium',
    },
    {
      'id': 'chem_04',
      'q': "Quel élément a le numéro atomique 6 ?",
      'opts': ['Oxygène', 'Azote', 'Carbone', 'Hydrogène'],
      'ans': 2,
      'cat': 'العلوم',
      'diff': 'easy',
    },
    {
      'id': 'chem_05',
      'q': "La loi des gaz parfaits ?",
      'opts': ['PV=nRT', 'P/V=RT', 'V=PT', 'P=V/T'],
      'ans': 0,
      'cat': 'العلوم',
      'diff': 'medium',
    },
    {
      'id': 'chem_06',
      'q': "Une liaison covalente implique...",
      'opts': ['Transfert d\'électrons', 'Partage d\'électrons', 'Force gravitationnelle', 'Magnétisme'],
      'ans': 1,
      'cat': 'العلوم',
      'diff': 'hard',
    },

    // الفرنسية (Français)
    {
      'id': 'fr_01',
      'q': "Quel est le synonyme de 'éphémère' ?",
      'opts': ['Durable', 'Éternel', 'Passager', 'Lourd'],
      'ans': 2,
      'cat': 'الفرنسية',
      'diff': 'medium',
    },
    {
      'id': 'fr_02',
      'q': "Conjuguez 'aller' au subjonctif présent (je) :",
      'opts': ['J\'aille', 'Je vais', 'J\'allais', 'J\'irai'],
      'ans': 0,
      'cat': 'الفرنسية',
      'diff': 'hard',
    },
    {
      'id': 'fr_03',
      'q': "Identifiez la figure de style : 'Cette obscure clarté'",
      'opts': ['Métaphore', 'Oxymore', 'Euphémisme', 'Antithèse'],
      'ans': 1,
      'cat': 'الفرنسية',
      'diff': 'veryHard',
    },
    {
      'id': 'fr_04',
      'q': "Quel est l'antonyme de 'altruiste' ?",
      'opts': ['Généreux', 'Égoïste', 'Brave', 'Intelligent'],
      'ans': 1,
      'cat': 'الفرنسية',
      'diff': 'medium',
    },

    // الفلسفة (Philosophy) - عينة بصعوبة عالية
    {
      'id': 'phil_01',
      'q': "من القائل: 'أنا أفكر، إذن أنا موجود'؟",
      'opts': ['كانط', 'أرسطو', 'ديكارت', 'نيتشه'],
      'ans': 2,
      'cat': 'الفلسفة',
      'diff': 'medium',
    },
    {
      'id': 'phil_02',
      'q': "ما هو المفهوم الأساسي في فلسفة كانط الأخلاقية؟",
      'opts': ['المنفعة المطلقة', 'الواجب القطعي', 'إرادة القوة', 'السعادة'],
      'ans': 1,
      'cat': 'الفلسفة',
      'diff': 'hard',
      'exp': 'الأمر المطلق (Categorical Imperative) هو أساس الأخلاق عند كانط.',
    },
    {
      'id': 'phil_03',
      'q': "من هو مؤسس الفلسفة الوجودية الحديثة؟",
      'opts': ['سورين كيركغارد', 'جان بول سارتر', 'مارتن هايدغر', 'ألبير كامو'],
      'ans': 0,
      'cat': 'الفلسفة',
      'diff': 'hard',
    },
    {
      'id': 'phil_04',
      'q': "ماذا تعني 'الديالكتيك' عند هيجل؟",
      'opts': ['الشك المنهجي', 'الأطروحة، النقيض، التوليف', 'العودة الأبدية', 'الوضعية المنطقية'],
      'ans': 1,
      'cat': 'الفلسفة',
      'diff': 'veryHard',
      'exp': 'Thesis, Antithesis, Synthesis',
    },
    {
      'id': 'phil_05',
      'q': "في 'أسطورة سيزيف'، كيف يرى كامو العبثية؟",
      'opts': ['كمشكلة يجب التخلص منها بالانتحار', 'كتناقض يجب قبوله والتمرد عليه', 'كوهم ديني', 'كنتيجة للمجتمع الرأسمالي'],
      'ans': 1,
      'cat': 'الفلسفة',
      'diff': 'veryHard',
    },
    {
      'id': 'phil_06',
      'q': "إلى ماذا يشير 'كهف أفلاطون'؟",
      'opts': ['الفرق بين العالم المحسوس وعالم المُثُل', 'مكان لتدريب الفلاسفة', 'أصل نشأة الكون', 'نهاية العالم'],
      'ans': 0,
      'cat': 'الفلسفة',
      'diff': 'hard',
    },
    {
      'id': 'phil_07',
      'q': "ما هو كتاب نيتشه الذي يتحدث فيه عن 'الإنسان الأعلى' (Übermensch)؟",
      'opts': ['نقد العقل الخالص', 'هكذا تكلم زرادشت', 'الجمهورية', 'العقد الاجتماعي'],
      'ans': 1,
      'cat': 'الفلسفة',
      'diff': 'hard',
    },
    {
      'id': 'phil_08',
      'q': "ما هو المبدأ الأساسي للنفعية (Utilitarianism)؟",
      'opts': ['الأخلاق تنبع من النوايا السليمة', 'تحقيق أكبر قدر من السعادة لأكبر عدد من الناس', 'الخضوع للقوانين الطبيعية', 'الإيمان بالقدر المكتوب'],
      'ans': 1,
      'cat': 'الفلسفة',
      'diff': 'medium',
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
