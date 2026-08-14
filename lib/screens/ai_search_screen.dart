import 'package:flutter/material.dart';
import '../widgets/app_notification.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as genai;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class AiSearchScreen extends StatefulWidget {
  const AiSearchScreen({super.key});

  @override
  State<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends State<AiSearchScreen> {
  final _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isTyping = false;

  late final genai.GenerativeModel _model;
  genai.ChatSession? _currentChat;
  final List<Map<String, String>> _guestMessages = [];

  @override
  void initState() {
    super.initState();
    const apiKey = 'AQ.Ab8RN6Jjn9X1' + 'TQDC4NSzAfXzXqbsebvQ9dPje2lvYG650Ou5GA';
    _model = genai.GenerativeModel(
      model: 'gemini-flash-latest',
      apiKey: apiKey,
      systemInstruction: genai.Content.system(
        'أنت MERAJ3I AI، المساعد التعليمي والعبقري للطلاب في موريتانيا والوطن العربي. '
        'دورك الأساسي هو تقديم شروحات دراسية ذكية واحترافية. يمكنك الإجابة على أي سؤال بذكاء فائق. '
        'نظّم إجاباتك بنقاط واضحة ومنسقة واحترافية. '
        'مهم جداً: أجب بنصوص عادية، ولا تستخدم إطلاقاً رموز التنسيق مثل النجمة (*) أو الشباك (#). '
        'تجنب تماماً العبارات الطفولية أو المبالغ فيها مثل "يا بطل المستقبل". '
        'كن دقيقاً ومباشراً ومنظماً.',
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isAuthenticated) {
        Provider.of<ChatProvider>(
          context,
          listen: false,
        ).loadSessions(auth.user!.uid);
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء اختيار الصورة')),
        );
      }
    }
  }

  void _sendMessage() async {
    final text = _promptController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    String? sessionId = chatProvider.currentSessionId;

    if (auth.isAuthenticated && sessionId == null) {
      sessionId = await chatProvider.createSession(
        auth.user!.uid,
        text.isEmpty ? 'صورة مرفقة' : text,
      );
    }

    String? base64Image;
    if (_selectedImage != null) {
      final bytes = await _selectedImage!.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    final userMessage = <String, String>{'role': 'user', 'text': text};
    if (base64Image != null) userMessage['image'] = base64Image;

    if (auth.isAuthenticated && sessionId != null) {
      await chatProvider.addMessage(auth.user!.uid, sessionId, userMessage);
    } else {
      setState(() {
        _guestMessages.add(userMessage);
        _currentChat ??= _startNewGuestChat();
      });
    }

    _promptController.clear();
    final imageFile = _selectedImage;
    setState(() {
      _isTyping = true;
      _selectedImage = null;
    });
    _scrollToBottom();

    try {
      final chatSession = _getChatSession(sessionId);

      genai.GenerateContentResponse response;
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        final content = genai.Content.multi([
          if (text.isNotEmpty) genai.TextPart(text),
          genai.DataPart('image/jpeg', bytes),
        ]);
        response = await chatSession.sendMessage(content);
      } else {
        response = await chatSession.sendMessage(genai.Content.text(text));
      }

      final responseText = response.text ?? 'لم أستطع معالجة هذا الطلب.';

      // إزالة الرموز النجمة والشباك من الرد
      final cleanText = responseText.replaceAll(RegExp(r'[\*\#]'), '');

      final aiMessage = {'role': 'model', 'text': cleanText};

      if (auth.isAuthenticated && sessionId != null) {
        await chatProvider.addMessage(auth.user!.uid, sessionId, aiMessage);
      } else {
        setState(() {
          _guestMessages.add(aiMessage);
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'حدث خطأ في الاتصال، يرجى المحاولة لاحقاً.';
        final errorText = e.toString().toLowerCase();

        if (errorText.contains('api key') ||
            errorText.contains('403') ||
            errorText.contains('unauthorized')) {
          errorMsg =
              'مفتاح الذكاء الاصطناعي (API Key) غير صالح أو منتهي الصلاحية.';
        } else if (errorText.contains('quota') || errorText.contains('429')) {
          errorMsg = 'لقد استنفدت الحد المسموح به للذكاء الاصطناعي حالياً.';
        } else if (errorText.contains('socket') ||
            errorText.contains('connection') ||
            errorText.contains('network')) {
          errorMsg = 'تأكد من اتصالك بالإنترنت ثم حاول مجدداً.';
        } else if (errorText.contains('turn')) {
          errorMsg = 'حدث خطأ في تسلسل المحادثة. حاول بدء محادثة جديدة.';
        }

        AppNotification.show(context, errorMsg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isTyping = false);
    }

    _scrollToBottom();
  }

  genai.ChatSession _getChatSession(String? sessionId) {
    if (_currentChat != null) return _currentChat!;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final session = chatProvider.currentSession;

    if (session != null) {
      final history = <genai.Content>[];
      String expectedRole = 'user';

      for (var m in session.messages) {
        if (m['role'] == expectedRole) {
          history.add(
            expectedRole == 'user'
                ? genai.Content.text(m['text']!)
                : genai.Content.model([genai.TextPart(m['text']!)]),
          );
          expectedRole = expectedRole == 'user' ? 'model' : 'user';
        }
      }

      try {
        _currentChat = _model.startChat(history: history);
      } catch (e) {
        // Fallback in case of history issues
        _currentChat = _model.startChat();
      }
    } else {
      _currentChat = _model.startChat();
    }
    return _currentChat!;
  }

  genai.ChatSession _startNewGuestChat() {
    return _model.startChat();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final currentSession = chatProvider.currentSession;
    final messages = auth.isAuthenticated
        ? (currentSession?.messages ?? [])
        : _guestMessages;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'MERAJ3I AI',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Text(
              'المساعد الذكي',
              style: GoogleFonts.tajawal(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_rounded),
            onPressed: () {
              if (auth.isAuthenticated) {
                chatProvider.setCurrentSession(null);
              } else {
                setState(() {
                  _guestMessages.clear();
                });
              }
              setState(() => _currentChat = null);
            },
            tooltip: 'محادثة جديدة',
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildHistoryDrawer(context),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? _buildWelcomeLayout()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              alignment: Alignment.centerRight,
              child: const SpinKitThreeBounce(
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHistoryDrawer(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'سجل المحادثات',
                    style: GoogleFonts.tajawal(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!auth.isAuthenticated)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'قم بتسجيل الدخول لحفظ سجل محادثاتك',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: chatProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: chatProvider.sessions.length,
                      itemBuilder: (context, index) {
                        final session = chatProvider.sessions[index];
                        final isSelected =
                            chatProvider.currentSessionId == session.id;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: AppTheme.primaryColor.withValues(
                            alpha: 0.05,
                          ),
                          leading: const Icon(Icons.chat_outlined, size: 20),
                          title: Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.tajawal(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          onTap: () {
                            chatProvider.setCurrentSession(session.id);
                            setState(() => _currentChat = null);
                            Navigator.pop(context);
                          },
                          trailing: isSelected
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => chatProvider.deleteSession(
                                    auth.user!.uid,
                                    session.id,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'أنا مراجعي AI',
            style: GoogleFonts.tajawal(
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'مساعدك الشخصي في المذاكرة والتحصيل العلمي',
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 48),
          _buildExampleCard('كيف أذاكر بذكاء للامتحان؟'),
          _buildExampleCard('اشرح لي قاعدة كان وأخواتها'),
          _buildExampleCard('ما هي أهم نصائح التفوق الدراسي؟'),
        ],
      ),
    );
  }

  Widget _buildExampleCard(String text) {
    return GestureDetector(
      onTap: () {
        _promptController.text = text;
        _sendMessage();
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E293B)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.2
                    : 0.05,
              ),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                size: 20,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF0F172A),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.primaryColor
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? Radius.zero : const Radius.circular(20),
            bottomRight: isUser ? const Radius.circular(20) : Radius.zero,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            if (message['image'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(message['image']!),
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Text(
              message['text'] ?? '',
              style: GoogleFonts.tajawal(
                color: isUser
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                height: 1.6,
                fontWeight: isUser ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: -10,
                          top: -10,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () =>
                                setState(() => _selectedImage = null),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.image_outlined,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: TextField(
                      controller: _promptController,
                      style: GoogleFonts.tajawal(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'اسأل مراجعي AI...',
                        hintStyle: GoogleFonts.tajawal(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
