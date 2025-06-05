// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'planet.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '당신의 우주, Youniverse',
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.orangeAccent,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const SolarSystemPage(),
    );
  }
}

class SolarSystemPage extends StatefulWidget {
  const SolarSystemPage({super.key});

  @override
  State<SolarSystemPage> createState() => _SolarSystemPageState();
}

class _SolarSystemPageState extends State<SolarSystemPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  List<Planet> planets = [];
  bool isLoading = true;
  bool _isSendingShout = false; // <<< ADDED for loading state

  final String _netlifyFunctionUrl =
      "https://subtle-kitsune-751533.netlify.app/.netlify/functions/getAdjustValue"; // <<< IMPORTANT: Use relative path for deployed app, or full for local testing if needed.

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _loadPlanets();
  }

  Future<void> _loadPlanets() async {
    final prefs = await SharedPreferences.getInstance();
    final planetsJson = prefs.getStringList('planets') ?? [];
    if (planetsJson.isEmpty) {
      planets = [];
      // _savePlanets(); // No need to save if empty initially
    } else {
      planets =
          planetsJson.map((json) => Planet.fromJson(jsonDecode(json))).toList();
    }
    setState(() {
      isLoading = false;
    });
    _sortPlanets();
  }

  Future<void> _savePlanets() async {
    final prefs = await SharedPreferences.getInstance();
    final planetsJson =
        planets.map((planet) => jsonEncode(planet.toJson())).toList();
    await prefs.setStringList('planets', planetsJson);
  }

  void _sortPlanets() {
    planets.sort((a, b) {
      final scoreA = a.importance * a.friendliness;
      final scoreB = b.importance * b.friendliness;
      return scoreB.compareTo(scoreA);
    });
  }

  bool _isPlanetNameUnique(String name, {Planet? excludePlanet}) {
    return !planets.any((planet) =>
        planet.name.toLowerCase() == name.toLowerCase() &&
        planet != excludePlanet);
  }

  void _showKakaoSyncDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카카오톡 친구 연동'),
        content: const Text(
          '카카오톡 친구들을 연동합니다.\n792명의 친구를 연동합니다.\n친밀도와 중요도가 높은 20개의 행성만 표시됩니다.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _addKakaoFriends();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _addKakaoFriends() {
    final random = math.Random();
    final colors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.brown,
      Colors.orange,
      Colors.lime,
      Colors.deepPurple,
      Colors.lightBlue,
      Colors.deepOrange,
    ];
    List<Planet> kakaoFriends = [
      Planet(
          name: "엄마",
          importance: 0.9,
          friendliness: 0.9,
          color: Colors.pink,
          speed: 1.2),
      Planet(
          name: "아빠",
          importance: 0.9,
          friendliness: 0.9,
          color: Colors.blue,
          speed: 0.9),
      Planet(
          name: "동생",
          importance: 0.3,
          friendliness: 0.5,
          color: Colors.green,
          speed: 1.4),
      Planet(
          name: "윤서현",
          importance: 0.7,
          friendliness: 1.0,
          color: Colors.orange,
          speed: 0.4),
      Planet(
          name: "최윤진 선생님",
          importance: 0.85,
          friendliness: 0.2,
          color: Colors.purple,
          speed: 0.7),
    ];
    for (int i = 1; i <= 45; i++) {
      kakaoFriends.add(Planet(
        name: "친구$i",
        importance: 0.2 + random.nextDouble() * 0.5,
        friendliness: 0.2 + random.nextDouble() * 0.5,
        color: colors[random.nextInt(colors.length)],
        speed: 0.3 + random.nextDouble() * 1.7,
      ));
    }
    setState(() {
      planets.removeWhere((planet) => planet.name.startsWith('친구'));
      planets.addAll(kakaoFriends);
      _sortPlanets();
    });
    _savePlanets();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('카카오톡 친구 50명이 성공적으로 연동되었습니다!'),
          backgroundColor: Colors.green),
    );
  }

  void _addPlanet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      builder: (context) => PlanetForm(
        onSave: (planet) {
          if (!_isPlanetNameUnique(planet.name)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('이미 "${planet.name}" 이름의 행성이 존재합니다. 다른 이름을 사용해주세요.'),
                  backgroundColor: Colors.red),
            );
            return false;
          }
          setState(() {
            planets.add(planet);
            _sortPlanets();
          });
          _savePlanets();
          return true;
        },
        checkNameUnique: (name) => _isPlanetNameUnique(name),
      ),
    );
  }

  void _editPlanet(int index) {
    final planetToEdit = planets[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      builder: (context) => PlanetForm(
        planet: planetToEdit,
        onSave: (planet) {
          if (planet.name.toLowerCase() != planetToEdit.name.toLowerCase() &&
              !_isPlanetNameUnique(planet.name, excludePlanet: planetToEdit)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('이미 "${planet.name}" 이름의 행성이 존재합니다. 다른 이름을 사용해주세요.'),
                  backgroundColor: Colors.red),
            );
            return false;
          }
          setState(() {
            final editIndex = planets
                .indexWhere((p) => p == planetToEdit); // Uses overridden ==
            if (editIndex != -1) {
              planets[editIndex] = planet;
            } else {
              // Fallback or error if original not found (should not happen with correct ==)
              print("Error: Could not find original planet to edit.");
              planets.add(planet); // Or handle as a new addition
            }
            _sortPlanets();
          });
          _savePlanets();
          return true;
        },
        onDelete: () {
          setState(() {
            planets.remove(planetToEdit); // Uses overridden ==
            _sortPlanets(); // Re-sort if needed
          });
          _savePlanets();
        },
        checkNameUnique: (name) =>
            _isPlanetNameUnique(name, excludePlanet: planetToEdit),
      ),
    );
  }

  void _deletePlanet(int index) {
    final planetToDelete = planets[index];
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('행성 삭제'),
        content: Text('${planetToDelete.name}님을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                planets.remove(planetToDelete); // Uses overridden ==
                _sortPlanets(); // Re-sort if needed
              });
              _savePlanets();
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // --- vvv NEW/MODIFIED CODE FOR CHATGPT FUNCTIONALITY vvv ---
  void _showShoutDialog() {
    final TextEditingController shoutController = TextEditingController();
    // Use the build context from _SolarSystemPageState
    final BuildContext pageContext = context;

    showDialog(
      context: pageContext, // Use the page's context to show the dialog
      builder: (dialogContext) {
        return StatefulBuilder(
            // <<< Use StatefulBuilder for loading state within dialog
            builder: (stfContext, setDialogState) {
          return AlertDialog(
            title: const Text("오늘 인간관계에 대해 하고 싶은 말을\n 우주에 외쳐보세요!"),
            content: Column(
              // <<< Wrap TextField in a Column for loading indicator
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: shoutController,
                  autofocus: true,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    hintText: "하고 싶은 말...",
                  ),
                ),
                if (_isSendingShout) // <<< Show loading indicator
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: _isSendingShout
                    ? null
                    : () {
                        // <<< Disable if sending
                        Navigator.of(dialogContext).pop();
                      },
                child: const Text("취소"),
              ),
              TextButton(
                onPressed: _isSendingShout
                    ? null
                    : () async {
                        // <<< Disable if sending
                        final message = shoutController.text.trim();
                        if (message.isEmpty) {
                          ScaffoldMessenger.of(pageContext).showSnackBar(
                            // Use pageContext
                            const SnackBar(
                                content: Text('메시지를 입력해주세요.'),
                                backgroundColor: Colors.orangeAccent),
                          );
                          return;
                        }

                        setDialogState(() {
                          // Update dialog state for loading
                          _isSendingShout = true;
                        });
                        // Use pageContext for _sendShoutToBackend if it needs context for ScaffoldMessenger
                        await _sendShoutToBackend(message, pageContext);

                        // Check if the dialog is still mounted before popping or updating state
                        if (Navigator.of(dialogContext).canPop()) {
                          Navigator.of(dialogContext).pop();
                        }
                        // Reset loading state for the main page
                        if (mounted) {
                          setState(() {
                            _isSendingShout = false;
                          });
                        }
                      },
                child: const Text("보내기"),
              ),
            ],
          );
        });
      },
    ).then((_) {
      shoutController.dispose();
      // Ensure _isSendingShout is reset if dialog is dismissed externally
      if (mounted && _isSendingShout) {
        setState(() {
          _isSendingShout = false;
        });
      }
    });
  }

  Future<void> _sendShoutToBackend(
      String message, BuildContext scaffoldContext) async {
    // For deployed app, path is relative. For local testing with `netlify dev`
    // use `http://localhost:YOUR_NETLIFY_DEV_PORT/.netlify/functions/chatWithGPT`
    // Ensure `_netlifyFunctionUrl` is set correctly. If it starts with '/', it assumes same host.
    // If you are testing locally and your Flutter app runs on a different port than netlify dev,
    // you MUST use the full URL for local testing (e.g., http://localhost:8888/.netlify/functions/chatWithGPT).
    // For a deployed app, "/.netlify/functions/chatWithGPT" is usually correct.

    // Determine the base URL dynamically for web builds to avoid CORS issues locally
    // String baseUrl = "https://subtle-kitsune-751533.netlify.app/";
    // String baseUrl = "http://127.0.0.1:5500/"; // For local testing with netlify dev
    // This kIsWeb check and Uri.base only works for web builds.
    // For mobile, you'd need the full deployed URL.
    // #  if (kIsWeb) {
    // #    baseUrl = Uri.base.origin; // e.g., http://localhost:PORT or https://your-site.netlify.app
    // #  } else {
    // #    // For mobile, you MUST use your deployed Netlify function URL
    // #    baseUrl = "https://your-netlify-site-name.netlify.app";
    // #  }
    // For simplicity, assuming relative path works for deployed web, or you hardcode for mobile.
    // If testing flutter web locally, and netlify dev is on a different port,
    // explicitly use: "http://localhost:8888" as baseUrl for local dev.
    // Let's assume for web deployment the relative path is okay.

    // final Uri functionUri = Uri.parse('$baseUrl.netlify/functions/getAdjustValue');
    final Uri functionUri = Uri.parse(
        _netlifyFunctionUrl); // If relative, needs base URL for non-web or local.
    // For now, let's assume it's just the path.

    try {
      final response = await http.post(
        functionUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String aiReply = data['reply'] ?? '응답을 받지 못했습니다.';
        print(aiReply);

        // Show success message with AI reply
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
            content: Text('AI 응답: $aiReply'),
            backgroundColor: Colors.lightBlue,
            duration: const Duration(seconds: 5), // Show longer
          ),
        );
      } else {
        // Handle non-200 responses
        String errorMessage = '메시지 전송 실패: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage += ' - ${errorData['error'] ?? response.body}';
        } catch (e) {
          errorMessage += ' - ${response.body}';
        }
        print('Error sending shout: $errorMessage');
        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
          SnackBar(
              content: Text(errorMessage), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      // Handle network errors or other exceptions
      print('Exception sending shout: $e');
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        SnackBar(
            content: Text('메시지 전송 중 오류 발생: $e'), backgroundColor: Colors.red),
      );
    }
  }
  // --- ^^^ NEW/MODIFIED CODE FOR CHATGPT FUNCTIONALITY ^^^ ---

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('당신의 우주', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: SolarSystemPainter(
                    planets: planets,
                    animationValue: _animationController.value,
                  ),
                  child: Container(),
                );
              },
            ),
      floatingActionButton: Padding(
        // <<< MODIFIED
        padding: const EdgeInsets.only(
            bottom: 0.0), // Adjust if FABs are too close to bottomNav
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 32.0),
              child: FloatingActionButton(
                heroTag: 'shout_to_universe_button',
                onPressed: _showShoutDialog,
                tooltip: '우주에 외치기',
                child: const Icon(Icons.campaign),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: "kakao_sync",
                  onPressed: _showKakaoSyncDialog,
                  backgroundColor: const Color.fromARGB(255, 255, 232, 18),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: ClipOval(
                      child: SvgPicture.asset(
                        'assets/kakao.svg', // Ensure this is in assets/ and pubspec.yaml
                        fit: BoxFit.cover,
                        placeholderBuilder: (BuildContext context) =>
                            const Icon(Icons.chat,
                                color: Colors.black, size: 30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FloatingActionButton(
                  heroTag: "add_planet",
                  onPressed: _addPlanet,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        height: 120,
        child: planets.isEmpty
            ? const Center(
                child: Text('행성이 없습니다.\n관계를 추가해보세요!',
                    style: TextStyle(color: Colors.grey)))
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: planets.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final planet = planets[index];
                  return Card(
                    color: Color.alphaBlend(
                        planet.color.withOpacity(0.3), Colors.grey[900]!),
                    child: InkWell(
                      onTap: () => _editPlanet(index),
                      onLongPress: () => _deletePlanet(index),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                    color: planet.color,
                                    shape: BoxShape.circle)),
                            const SizedBox(height: 4),
                            Text(planet.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            Text('중요도: ${(planet.importance * 100).toInt()}%',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey)),
                            Text('친밀도: ${(planet.friendliness * 100).toInt()}%',
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// SolarSystemPainter class remains the same
class SolarSystemPainter extends CustomPainter {
  final List<Planet> planets;
  final double animationValue;

  SolarSystemPainter({required this.planets, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final starPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 200; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5;
      starPaint.color =
          Colors.white.withOpacity(0.3 + random.nextDouble() * 0.7);
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.45;
    final sortedPlanets = List<Planet>.from(planets);
    sortedPlanets.sort((a, b) => (b.importance * b.friendliness)
        .compareTo(a.importance * a.friendliness));
    final topPlanets = sortedPlanets.take(20).toList();
    final orbitPaint = Paint()
      ..color = Colors.grey.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var planet in topPlanets) {
      final orbitRadius = maxRadius * (0.3 + ((1 - planet.friendliness) * 0.7));
      canvas.drawCircle(center, orbitRadius, orbitPaint);
    }
    final sunPaint = Paint()..color = Colors.amber[600]!;
    canvas.drawCircle(center, 30, sunPaint);
    final sunGlowPaint = Paint()
      ..shader = RadialGradient(colors: [
        Colors.amber.withOpacity(0.7),
        Colors.amber.withOpacity(0)
      ]).createShader(Rect.fromCircle(center: center, radius: 60));
    canvas.drawCircle(center, 60, sunGlowPaint);
    for (var i = 0; i < topPlanets.length; i++) {
      final planet = topPlanets[i];
      final orbitRadius = maxRadius * (0.3 + ((1 - planet.friendliness) * 0.7));
      final angle = 2 * math.pi * animationValue * planet.speed + (i * 0.5);
      final x = center.dx + orbitRadius * math.cos(angle);
      final y = center.dy + orbitRadius * math.sin(angle);
      final planetRadius = 15 + (planet.importance * 15);
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x + 2, y + 2), planetRadius, shadowPaint);
      final planetPaint = Paint()..color = planet.color;
      canvas.drawCircle(Offset(x, y), planetRadius, planetPaint);
      final textSpan = TextSpan(
        text: planet.name,
        style: TextStyle(
            color: _getContrastingTextColor(planet.color),
            fontSize: math.min(planetRadius * 0.4, 12),
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                  blurRadius: 3.0,
                  color: Colors.black,
                  offset: Offset(0.5, 0.5))
            ]),
      );
      final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center);
      textPainter.layout(maxWidth: planetRadius * 1.8);
      if (planetRadius > 15) {
        textPainter.paint(canvas,
            Offset(x - textPainter.width / 2, y - textPainter.height / 2));
      }
    }
  }

  Color _getContrastingTextColor(Color backgroundColor) => Colors.white;

  @override
  bool shouldRepaint(covariant SolarSystemPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.planets != planets;
}

// PlanetForm class remains the same (ensure its onSave returns bool and onDelete is VoidCallback)
class PlanetForm extends StatefulWidget {
  final Planet? planet;
  final bool Function(Planet planet) onSave; // <<< MODIFIED to return bool
  final VoidCallback? onDelete;
  final bool Function(String name)? checkNameUnique;

  const PlanetForm({
    super.key,
    this.planet,
    required this.onSave,
    this.onDelete,
    this.checkNameUnique,
  });

  @override
  State<PlanetForm> createState() => _PlanetFormState();
}

class _PlanetFormState extends State<PlanetForm> {
  late TextEditingController _nameController;
  late double _importance;
  late double _friendliness;
  late Color _color;
  late double _speed;
  String? _nameError;

  final List<Color> _availableColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.pink,
    Colors.indigo,
    Colors.cyan,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.planet?.name ?? '');
    _importance = widget.planet?.importance ?? 0.5;
    _friendliness = widget.planet?.friendliness ?? 0.5;
    _color = widget.planet?.color ?? _availableColors[0];
    _speed = widget.planet?.speed ?? (0.3 + math.Random().nextDouble() * 1.7);
    if (widget.planet != null) {
      // Check uniqueness on init if editing an existing name
      _checkNameUniqueness(widget.planet!.name, isInitialCheck: true);
    }
  }

  void _checkNameUniqueness(String value, {bool isInitialCheck = false}) {
    if (value.isEmpty) {
      setState(() => _nameError = null);
      return;
    }
    if (widget.checkNameUnique != null) {
      bool isUnique;
      if (widget.planet != null &&
          value.toLowerCase() == widget.planet!.name.toLowerCase() &&
          isInitialCheck) {
        // If it's the initial check for an existing planet with its own name, it's considered "unique" for editing itself.
        isUnique = true;
      } else {
        isUnique = widget.checkNameUnique!(value);
      }
      setState(() => _nameError = isUnique ? null : '이미 존재하는 이름입니다');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext pageContext) {
    // Renamed context for clarity
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(pageContext).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.planet == null ? '새로운 관계 추가하기' : '관계 직접 수정하기',
            style: Theme.of(pageContext)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
                labelText: '이름',
                border: const OutlineInputBorder(),
                errorText: _nameError),
            onChanged: _checkNameUniqueness,
          ),
          const SizedBox(height: 16),
          Text('중요도: ${(_importance * 100).toInt()}%'),
          Slider(
              value: _importance,
              onChanged: (value) => setState(() => _importance = value),
              label: '중요도'),
          const SizedBox(height: 8),
          Text('친밀도: ${(_friendliness * 100).toInt()}%'),
          Slider(
              value: _friendliness,
              onChanged: (value) => setState(() => _friendliness = value),
              label: '친밀도'),
          const SizedBox(height: 8),
          Text('나와의 인력: ${(_importance * _friendliness * 100).toInt()}',
              style: const TextStyle(
                  color: Colors.amber, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('색깔:'),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableColors.length,
              itemBuilder: (context, index) {
                final color = _availableColors[index];
                final isSelected = color.value == _color.value;
                return GestureDetector(
                  onTap: () => setState(() => _color = color),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 5)
                            ]
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              final currentName = _nameController.text.trim();
              _checkNameUniqueness(currentName); // Final check before save

              if (currentName.isEmpty) {
                ScaffoldMessenger.of(pageContext)
                    .showSnackBar(const SnackBar(content: Text('이름을 입력해주세요.')));
                return;
              }
              if (_nameError != null) {
                ScaffoldMessenger.of(pageContext).showSnackBar(
                    const SnackBar(content: Text('이름이 중복됩니다. 다른 이름을 사용해주세요.')));
                return;
              }
              final planet = Planet(
                  name: currentName,
                  importance: _importance,
                  friendliness: _friendliness,
                  color: _color,
                  speed: _speed);
              final success = widget.onSave(planet);
              if (success) {
                // Only pop if onSave indicates success (e.g., no duplicate name from parent)
                Navigator.pop(pageContext);
              }
            },
            child: const Text('저장하기'),
          ),
          if (widget.planet != null) ...[
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: pageContext, // Use pageContext
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('행성 삭제'),
                    content: Text(
                        '${widget.planet!.name}님을 정말 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('취소')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext); // Close confirmation
                          if (widget.onDelete != null) {
                            widget.onDelete!();
                          }
                          Navigator.pop(pageContext); // Close form
                        },
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('삭제하기'),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
