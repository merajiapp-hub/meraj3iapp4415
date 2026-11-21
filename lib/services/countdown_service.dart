import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/countdown_event.dart';

class CountdownService {
  CountdownService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('countdown_events');

  DocumentReference<Map<String, dynamic>> get _configDoc =>
      _firestore.collection('app_settings').doc('countdown_config');

  static List<CountdownEvent> get defaultEvents => [
    CountdownEvent(
      id: 'default_vacation_1',
      title: 'عطلة نهاية الفصل الأول',
      type: 'vacation',
      description: 'إجازة نهاية الفصل الدراسي الأول لجميع المراحل التعليمية',
      targetDate: DateTime.utc(2026, 12, 25, 8, 0),
      cardColor: '#EA580C',
      iconName: 'beach_access',
      dueMessage: 'بدأت عطلة نهاية الفصل الأول! عطلة سعيدة وممتعة للجميع',
      endMessage: 'انتهت عطلة الفصل الأول، عودة موفقة ومباركة لمقاعد الدراسة',
      order: 1,
    ),
    CountdownEvent(
      id: 'default_vacation_2',
      title: 'عطلة نهاية الفصل الثاني',
      type: 'vacation',
      description: 'إجازة نهاية الفصل الدراسي الثاني وبداية الاستعداد للامتحانات',
      targetDate: DateTime.utc(2027, 3, 27, 8, 0),
      cardColor: '#D97706',
      iconName: 'wb_sunny',
      dueMessage: 'بدأت عطلة نهاية الفصل الثاني! إجازة طيبة ومفيدة لجميع الطلاب',
      endMessage: 'انتهت عطلة الفصل الثاني، بالتوفيق في الفصل الختامي والامتحانات',
      order: 2,
    ),
    CountdownEvent(
      id: 'default_vacation_3',
      title: 'العطلة الصيفية الكبرى',
      type: 'vacation',
      description: 'العطلة الصيفية السنوية بعد ختام العام الدراسي والامتحانات',
      targetDate: DateTime.utc(2027, 7, 2, 8, 0),
      cardColor: '#CA8A04',
      iconName: 'pool',
      dueMessage: 'انطلقت العطلة الصيفية الكبرى! عطلة مميزة وسعيدة للجميع',
      endMessage: 'انتهت العطلة الصيفية، نتمنى لكم عاماً دراسياً جديداً حافلاً بالتميز والنجاح',
      order: 3,
    ),
    CountdownEvent(
      id: 'default_exam_1',
      title: 'مسابقة دخول السنة الأولى إعدادية (Concours)',
      type: 'exam',
      description: 'الامتحان الوطني لدخول السنة الأولى الإعدادية',
      targetDate: DateTime.utc(2027, 6, 1, 8, 0),
      cardColor: '#0F766E',
      iconName: 'school',
      dueMessage: 'انطلقت اليوم مسابقة دخول الإعدادية! نسأل الله التوفيق لأبنائنا التلاميذ',
      endMessage: 'انتهت مسابقة دخول الإعدادية، نتمنى التوفيق والنجاح لجميع المترشحين',
      order: 4,
    ),
    CountdownEvent(
      id: 'default_exam_2',
      title: 'امتحان شهادة ختم الدروس الإعدادية (Brevet)',
      type: 'exam',
      description: 'امتحان شهادة ختم الدروس الإعدادية (BEPC)',
      targetDate: DateTime.utc(2027, 6, 7, 8, 0),
      cardColor: '#0D9488',
      iconName: 'history_edu',
      dueMessage: 'حان موعد امتحان شهادة ختم الدروس الإعدادية! بالتوفيق والنجاح',
      endMessage: 'انتهى امتحان شهادة ختم الدروس الإعدادية، أمنياتنا لكم بأعلى الدرجات',
      order: 5,
    ),
    CountdownEvent(
      id: 'default_exam_3',
      title: 'امتحان البكالوريا الفنية (Bac Technique)',
      type: 'exam',
      description: 'امتحان شهادة البكالوريا للتعليم الفني والمهني',
      targetDate: DateTime.utc(2027, 6, 14, 8, 0),
      cardColor: '#047857',
      iconName: 'engineering',
      dueMessage: 'انطلق امتحان البكالوريا الفنية! سدد الله خطاكم وألهمكم الصواب',
      endMessage: 'انتهى امتحان البكالوريا الفنية، نتمنى التميز والنجاح لكافة المترشحين',
      order: 6,
    ),
    CountdownEvent(
      id: 'default_exam_4',
      title: 'امتحان الدورة العادية للبكالوريا (Bac Normal)',
      type: 'exam',
      description: 'الدورة العادية لامتحان شهادة البكالوريا الوطنية لكافة الشعب',
      targetDate: DateTime.utc(2027, 6, 21, 8, 0),
      cardColor: '#0F766E',
      iconName: 'workspace_premium',
      dueMessage: 'حان موعد الدورة العادية للبكالوريا! أملنا فيكم كبير وفالكم النجاح والتميز',
      endMessage: 'انتهت الدورة العادية للبكالوريا، أمنياتنا القلبية بالتفوق لجميع طلابنا الأعزاء',
      order: 7,
    ),
    CountdownEvent(
      id: 'default_exam_5',
      title: 'امتحان الدورة التكميلية للبكالوريا (Bac Complémentaire)',
      type: 'exam',
      description: 'الدورة التكميلية لامتحان شهادة البكالوريا',
      targetDate: DateTime.utc(2027, 7, 19, 8, 0),
      cardColor: '#115E59',
      iconName: 'edit_note',
      dueMessage: 'انطلقت الدورة التكميلية للبكالوريا! فرصة متجددة للظفر بالشهادة',
      endMessage: 'انتهت الدورة التكميلية للبكالوريا، كل التوفيق لجميع المشاركين',
      order: 8,
    ),
    CountdownEvent(
      id: 'default_comp_1',
      title: 'مسابقة دخول مؤسسات الامتياز (Excellence)',
      type: 'competition',
      description: 'المسابقة الوطنية لدخول ثانويات وإعداديات الامتياز',
      targetDate: DateTime.utc(2027, 7, 26, 8, 0),
      cardColor: '#14B8A6',
      iconName: 'military_tech',
      dueMessage: 'انطلقت مسابقة دخول مؤسسات الامتياز! تنافس شريف ونجاح مستحق للفرسان',
      endMessage: 'انتهت مسابقة مؤسسات الامتياز، تهانينا ومبارك لجميع المتأهلين',
      order: 9,
    ),
  ];

  Stream<List<CountdownEvent>> streamActiveEvents() {
    return _collection
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            // إذا لم توجد وثائق في قاعدة البيانات، نعرض المواعيد الافتراضية الرسمية
            return defaultEvents;
          }
          final list = snapshot.docs
              .map(CountdownEvent.fromFirestore)
              .where((ev) => ev.isActive && !ev.shouldHide)
              .toList()
            ..sort((a, b) => a.order.compareTo(b.order));
          return list.isEmpty ? defaultEvents : list;
        });
  }

  Stream<bool> streamCountdownEnabled() {
    return _configDoc.snapshots().map((snapshot) {
      if (!snapshot.exists) return true;
      return snapshot.data()?['countdown_enabled'] != false;
    });
  }

  Future<void> seedDefaultCountdownsIfEmpty() async {
    try {
      final snapshot = await _collection.limit(1).get();
      if (snapshot.docs.isNotEmpty) return;

      final batch = _firestore.batch();
      for (final ev in defaultEvents) {
        final docRef = _collection.doc();
        final map = ev.toMap();
        map['createdAt'] = FieldValue.serverTimestamp();
        batch.set(docRef, map);
      }
      await batch.commit();
    } catch (_) {}
  }
}
