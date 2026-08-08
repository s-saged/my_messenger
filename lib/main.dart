import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // فحص هل البيانات محفوظة محلياً قبل فتح التطبيق
  final prefs = await SharedPreferences.getInstance();
  final savedId = prefs.getString('saved_user_id');
  final savedName = prefs.getString('saved_user_name');

  runApp(CyberMessengerApp(
    initialId: savedId,
    initialName: savedName,
  ));
}

class CyberMessengerApp extends StatelessWidget {
  final String? initialId;
  final String? initialName;

  const CyberMessengerApp({super.key, this.initialId, this.initialName});

  @override
  Widget build(BuildContext context) {
    // لو البيانات متسجلة يدخل مباشرة على الصفحة الرئيسية
    final bool isLoggedIn = initialId != null && initialName != null;

    return MaterialApp(
      title: 'Cyber Messenger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF06B6D4),
          surface: Color(0xFF131C2E),
        ),
      ),
      home: isLoggedIn
          ? HomeScreen(myId: initialId!, myName: initialName!)
          : const IdentitySetupScreen(),
    );
  }
}

// ==================== شاشة تسجيل الـ ID الأولية ====================
class IdentitySetupScreen extends StatefulWidget {
  const IdentitySetupScreen({super.key});

  @override
  State<IdentitySetupScreen> createState() => _IdentitySetupScreenState();
}

class _IdentitySetupScreenState extends State<IdentitySetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  late String _generatedId;

  @override
  void initState() {
    super.initState();
    _generateRandomId();
  }

  void _generateRandomId() {
    final random = Random();
    final randomNum = 1000 + random.nextInt(9000);
    setState(() {
      _generatedId = 'user_$randomNum';
    });
  }

  void _saveAndProceed() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('برجاء كتابة اسمك أولاً!')),
      );
      return;
    }

    // 1. حفظ البيانات في Firebase Firestore
    await FirebaseFirestore.instance.collection('users').doc(_generatedId).set({
      'name': name,
      'userId': _generatedId,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. حفظ البيانات محلياً على الموبايل لمنع طلبها مرة أخرى عند إعادة فتح التطبيق
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_user_id', _generatedId);
    await prefs.setString('saved_user_name', name);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(myId: _generatedId, myName: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E17), Color(0xFF1E1035)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x806366F1),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                    color: Color(0xFF131C2E),
                  ),
                  child: const Icon(Icons.bolt, size: 50, color: Color(0xFF06B6D4)),
                ),
                const SizedBox(height: 24),
                const Text(
                  'CYBER MESSENGER',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ادخل اسمك للبدء في استخدام التطبيق',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _customInputDecoration('اكتب اسمك هنا...', Icons.person),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131C2E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x1AFFFFFF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fingerprint, color: Color(0xFF06B6D4)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'معرف الحساب (ID التلقائي)',
                              style: TextStyle(color: Colors.white38, fontSize: 10),
                            ),
                            Text(
                              _generatedId,
                              style: const TextStyle(
                                color: Color(0xFF06B6D4),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white54, size: 20),
                        tooltip: 'توليد ID آخر',
                        onPressed: _generateRandomId,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saveAndProceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 8,
                      shadowColor: const Color(0x806366F1),
                    ),
                    child: const Text(
                      'الدخول إلى الرسائل 🚀',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _customInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: const Color(0xFF131C2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x0DFFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF06B6D4)),
      ),
    );
  }
}

// ==================== الشاشة الرئيسية: قائمة الأصدقاء (Chats List) ====================
class HomeScreen extends StatefulWidget {
  final String myId;
  final String myName;

  const HomeScreen({super.key, required this.myId, required this.myName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showAddFriendDialog() {
    final TextEditingController friendIdController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF131C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'إضافة صديق جديد',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: friendIdController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'ادخل الـ ID الخاص بالصديق...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF06B6D4)),
                  filled: true,
                  fillColor: const Color(0xFF0A0E17),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final targetId = friendIdController.text.trim().toLowerCase();
                    if (targetId.isNotEmpty) {
                      if (targetId == widget.myId) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('لا يمكنك إضافة حسابك الشخصي!')),
                        );
                        return;
                      }

                      final doc = await _firestore.collection('users').doc(targetId).get();
                      String friendName = targetId;
                      if (doc.exists) {
                        friendName = doc.data()?['name'] ?? targetId;
                      }

                      await _firestore
                          .collection('users')
                          .doc(widget.myId)
                          .collection('friends')
                          .doc(targetId)
                          .set({
                        'friendId': targetId,
                        'friendName': friendName,
                        'addedAt': FieldValue.serverTimestamp(),
                      });

                      if (!mounted) return;
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('إضافة لقائمة المحادثات 💬', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // تسجيل الخروج لو أحببت في أي وقت مسح الجلسة
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const IdentitySetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF131C2E),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.myName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Row(
              children: [
                Text('ID: ${widget.myId}', style: const TextStyle(fontSize: 11, color: Color(0xFF06B6D4))),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.myId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ الـ ID للحافظة!')),
                    );
                  },
                  child: const Icon(Icons.copy, size: 12, color: Colors.white54),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF06B6D4)),
            onPressed: _showAddFriendDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
            tooltip: 'تسجيل الخروج',
            onPressed: _logout,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(widget.myId)
            .collection('friends')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 70, color: Color(0x26FFFFFF)),
                  SizedBox(height: 16),
                  Text('لا توجد محادثات حتى الآن', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('اضغط على زر الإضافة للبحث بـ ID الصديق', style: TextStyle(color: Colors.white30, fontSize: 12)),
                ],
              ),
            );
          }

          final friends = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friendData = friends[index].data() as Map<String, dynamic>;
              final friendId = friendData['friendId'];
              final friendName = friendData['friendName'];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF131C2E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x0DFFFFFF)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0x336366F1),
                    child: Text(
                      friendName.isNotEmpty ? friendName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  title: Text(friendName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('ID: $friendId', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SingleChatScreen(
                          myId: widget.myId,
                          friendId: friendId,
                          friendName: friendName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: _showAddFriendDialog,
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
    );
  }
}

// ==================== شاشة المحادثة الفردية (Single Chat) ====================
class SingleChatScreen extends StatefulWidget {
  final String myId;
  final String friendId;
  final String friendName;

  const SingleChatScreen({
    super.key,
    required this.myId,
    required this.friendId,
    required this.friendName,
  });

  @override
  State<SingleChatScreen> createState() => _SingleChatScreenState();
}

class _SingleChatScreenState extends State<SingleChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isBlocked = false;

  String get _chatId {
    List<String> ids = [widget.myId, widget.friendId];
    ids.sort();
    return ids.join('_');
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isBlocked) return;

    _msgController.clear();

    await _firestore
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .add({
      'senderId': widget.myId,
      'receiverId': widget.friendId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _toggleBlock() async {
    setState(() {
      _isBlocked = !_isBlocked;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBlocked ? 'تم حظر ${widget.friendName}' : 'تم إلغاء الحظر'),
        backgroundColor: _isBlocked ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF131C2E),
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF06B6D4),
              child: Text(
                widget.friendName.isNotEmpty ? widget.friendName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.friendName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                Text(widget.friendId, style: const TextStyle(fontSize: 10, color: Colors.white38)),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white54),
            color: const Color(0xFF131C2E),
            onSelected: (value) {
              if (value == 'block') _toggleBlock();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'block',
                child: Text(
                  _isBlocked ? 'إلغاء الحظر (Unblock)' : 'حظر الشخص (Block)',
                  style: TextStyle(color: _isBlocked ? Colors.green : Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isBlocked)
            Container(
              width: double.infinity,
              color: const Color(0x33FF5252),
              padding: const EdgeInsets.all(8),
              child: const Text(
                'لقد قمت بحظر هذا المستخدم. لن تتمكن من إرسال رسائل.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('ابدأ المحادثة الآن! 👋', style: TextStyle(color: Colors.white30)),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == widget.myId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          gradient: isMe
                              ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)])
                              : null,
                          color: isMe ? null : const Color(0xFF131C2E),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 2),
                            bottomRight: Radius.circular(isMe ? 2 : 16),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF131C2E),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    enabled: !_isBlocked,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _isBlocked ? 'المستخدم محظور...' : 'اكتب رسالتك...',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF0A0E17),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _isBlocked ? Colors.grey : const Color(0xFF06B6D4),
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.black, size: 18),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}