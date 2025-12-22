import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:flutter/material.dart';
import 'dart:math';
import '../data/turkish_words.dart';
import '../service/database_service.dart'; 
import '../app_theme.dart';


class WordLocation {
  final String word;
  final int startRow;
  final int startCol;
  final Axis direction;
  WordLocation({required this.word, required this.startRow, required this.startCol, required this.direction});
}

class GameLevel {
  final String sourceLetters;
  final List<WordLocation> words;
  GameLevel({required this.sourceLetters, required this.words});
}

class LevelGenerator {
  static GameLevel generateLevel() {
    final random = Random();
    if (kTurkishDictionary.isEmpty) return GameLevel(sourceLetters: "HATA", words: []);

    int attempts = 0;
    while (attempts < 20) {
      attempts++;
      List<String> longWords = kTurkishDictionary.where((w) => w.length >= 6 && w.length <= 8).toList();
      if (longWords.isEmpty) longWords = ["MARKET"]; 
      
      String rootWord = longWords[random.nextInt(longWords.length)];
      List<String> rootChars = rootWord.split('');

      List<String> subWords = [];
      for (String dictWord in kTurkishDictionary) {
        if (dictWord.length < 3) continue;
        if (dictWord == rootWord) { subWords.add(dictWord); continue; }
        if (_canBeFormed(dictWord, rootChars)) subWords.add(dictWord);
      }

      subWords.sort((a, b) => b.length.compareTo(a.length));
      if (subWords.length > 7) subWords = subWords.sublist(0, 7);

      List<WordLocation> placedWords = [];
      Map<String, String> occupiedCells = {}; 

      String firstWord = subWords[0];
      int startRow = 6; int startCol = 2; 
      placedWords.add(WordLocation(word: firstWord, startRow: startRow, startCol: startCol, direction: Axis.horizontal));
      _markCells(occupiedCells, firstWord, startRow, startCol, Axis.horizontal);

      for (int i = 1; i < subWords.length; i++) {
        String currentWord = subWords[i];
        bool placed = false;
        for (var existing in List.from(placedWords)) {
          if (placed) break;
          for (int c1 = 0; c1 < currentWord.length; c1++) {
            if (placed) break;
            for (int c2 = 0; c2 < existing.word.length; c2++) {
               if (currentWord[c1] == existing.word[c2]) {
                 Axis newDir = existing.direction == Axis.horizontal ? Axis.vertical : Axis.horizontal;
                 int newRow = existing.direction == Axis.horizontal ? existing.startRow - c1 : existing.startRow + c2;
                 int newCol = existing.direction == Axis.horizontal ? existing.startCol + c2 : existing.startCol - c1;
                 if(existing.direction == Axis.vertical) { newRow = existing.startRow + c2; newCol = existing.startCol - c1; }
                 if (_canPlace(occupiedCells, currentWord, newRow, newCol, newDir)) {
                   placedWords.add(WordLocation(word: currentWord, startRow: newRow, startCol: newCol, direction: newDir));
                   _markCells(occupiedCells, currentWord, newRow, newCol, newDir);
                   placed = true; break;
                 }
               }
            }
          }
        }
      }

      if (placedWords.length >= 3 || attempts >= 20) {
        rootChars.shuffle();
        return GameLevel(sourceLetters: rootChars.join(), words: placedWords);
      }
    }
    return GameLevel(sourceLetters: "HATA", words: []);
  }

  static bool _canBeFormed(String word, List<String> sourceChars) {
    List<String> pool = List.from(sourceChars);
    for (int i = 0; i < word.length; i++) {
      if (pool.contains(word[i])) pool.remove(word[i]); else return false;
    }
    return true;
  }
  static void _markCells(Map<String, String> grid, String word, int r, int c, Axis dir) {
    for (int i = 0; i < word.length; i++) {
      int row = dir == Axis.vertical ? r + i : r;
      int col = dir == Axis.horizontal ? c + i : c;
      grid["${row}_$col"] = word[i];
    }
  }
  static bool _canPlace(Map<String, String> grid, String word, int r, int c, Axis dir) {
    for (int i = 0; i < word.length; i++) {
      int row = dir == Axis.vertical ? r + i : r;
      int col = dir == Axis.horizontal ? c + i : c;
      String key = "${row}_$col";
      if (grid.containsKey(key) && grid[key] != word[i]) return false;
    }
    return true;
  }
}

// --- OYUN EKRANI ---

class WordGameScreen extends StatefulWidget {
  const WordGameScreen({super.key});
  @override
  State<WordGameScreen> createState() => _WordGameScreenState();
}

class _WordGameScreenState extends State<WordGameScreen> {
  GameLevel? currentLevel;
  int completedCount = 0;
  bool isLoading = true;
  
  // Veritabanındaki puanı burada anlık takip edeceğiz
  int _currentDbScore = 0; 
  final int hintCost = 10; 

  List<String> foundWords = [];
  List<int> selectedIndexes = [];
  Set<String> revealedCells = {};

  List<String> wheelLetters = [];

  Offset? currentDragPosition;
  List<Offset> letterPositions = [];
  
  double wheelRadius = 80;
  double letterSize = 50;  
  double centerX = 0; 
  double centerY = 0;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    if (kTurkishDictionary.isEmpty) await WordRepository.loadDictionary();
    _startNewLevel();
  }

  void _startNewLevel() {
    setState(() {
      isLoading = false;
      currentLevel = LevelGenerator.generateLevel();
      wheelLetters = currentLevel!.sourceLetters.split('');
      foundWords.clear();
      selectedIndexes.clear();
      letterPositions.clear();
      revealedCells.clear();
    });
  }

  void _onShuffle() {
    setState(() {
      wheelLetters.shuffle(); 
      selectedIndexes.clear(); 
      currentDragPosition = null;
    });
  }

  // --- GÜNCELLENEN İPUCU FONKSİYONU ---
  void _useHint() async {
    // 1. Önce açılacak harf var mı diye bakalım (Boşuna işlem yapmayalım)
    List<String> candidates = [];
    if (currentLevel != null) {
      for (var wordLoc in currentLevel!.words) {
        if (foundWords.contains(wordLoc.word)) continue;
        for (int i = 0; i < wordLoc.word.length; i++) {
          int r = wordLoc.startRow + (wordLoc.direction == Axis.vertical ? i : 0);
          int c = wordLoc.startCol + (wordLoc.direction == Axis.horizontal ? i : 0);
          String key = "${r}_$c";
          if (!revealedCells.contains(key)) candidates.add(key);
        }
      }
    }

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Açılacak harf kalmadı!")));
      return;
    }

    // 2. Veritabanından durumu çek
    // (first diyerek o anki veriyi tek seferlik alıyoruz)
    DocumentSnapshot snap = await DatabaseService().getUserStream().first;
    if (!snap.exists || snap.data() == null) return;
    
    Map<String, dynamic> data = snap.data() as Map<String, dynamic>;
    int freeHints = data['free_hints'] ?? 0;
    int currentScore = data['score'] ?? 0;

    bool isSuccess = false;

    // 3. Karar Anı: Bedava mı, Paralı mı?
    if (freeHints > 0) {
       //  hakkı var, onu kullan
       await DatabaseService().useFreeHint();
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ücretsiz ipucu kullanıldı!"), duration: Duration(milliseconds: 800)));
       isSuccess = true;
    } else {
       // Hakkı yok, parası yetiyor mu?
       if (currentScore >= hintCost) {
         await DatabaseService().addScore(-hintCost);
         isSuccess = true;
       } else {
         if (!mounted) return;
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yetersiz Puan!"), backgroundColor: Colors.red));
       }
    }

    // 4. Eğer ödeme/hak kullanımı başarılıysa harfi aç
    if (isSuccess) {
      setState(() {
        String luckyCell = candidates[Random().nextInt(candidates.length)];
        revealedCells.add(luckyCell);
      });
    }
  }

  void _onPanStart(DragStartDetails details) { _handleTouch(details.localPosition); }
  void _onPanUpdate(DragUpdateDetails details) { setState(() { currentDragPosition = details.localPosition; }); _handleTouch(details.localPosition); }
  void _onPanEnd(DragEndDetails details) {
    if (currentLevel == null) return;
    String formedWord = selectedIndexes.map((i) => wheelLetters[i]).join();
    bool isValidWord = currentLevel!.words.any((w) => w.word == formedWord);
    if (isValidWord && !foundWords.contains(formedWord)) {
      setState(() { foundWords.add(formedWord); }); _checkLevelFinish();
    } else if (foundWords.contains(formedWord)) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Zaten bulundu!"), duration: Duration(milliseconds: 500)));
    }
    setState(() { selectedIndexes.clear(); currentDragPosition = null; });
  }

  void _handleTouch(Offset localPosition) {
    if (currentLevel == null) return;
    for (int i = 0; i < wheelLetters.length; i++) {
      if (selectedIndexes.contains(i)) continue;
      Offset letterPos = letterPositions[i];
      if ((localPosition - letterPos).distance < 30) {
        setState(() { selectedIndexes.add(i); currentDragPosition = letterPos; }); break;
      }
    }
  }

  // --- GÜNCELLENEN BÖLÜM SONU ---
  void _checkLevelFinish() {
    if (currentLevel == null) return;
    if (foundWords.length == currentLevel!.words.length) {
      
      
      DatabaseService().addScore(50);

      showDialog(
        context: context, barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("Tebrikler!", textAlign: TextAlign.center),
          content: Column( mainAxisSize: MainAxisSize.min, children: [ const Icon(Icons.emoji_events_rounded, size: 80, color: Colors.orange), const SizedBox(height: 16), Text("${completedCount + 1}. Bulmaca Tamamlandı!", style: const TextStyle(fontSize: 18)), const SizedBox(height: 8), const Text("+50 Puan", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))]),
          actions: [ ElevatedButton( onPressed: () { 
            Navigator.pop(context); 
            setState(() { completedCount++; isLoading = true; }); 
            Future.delayed(const Duration(milliseconds: 500), () { _startNewLevel(); }); }, child: const Text("SONRAKİ BULMACA"))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || currentLevel == null) return Scaffold(backgroundColor: kBackgroundColor, appBar: AppBar(title: const Text("Yükleniyor...")), body: const Center(child: CircularProgressIndicator()));
    
    final size = MediaQuery.of(context).size;
    centerX = size.width / 2;
    centerY = size.height - 250; 

    if (letterPositions.isEmpty || letterPositions.length != wheelLetters.length) {
      letterPositions.clear();
      double step = 2 * pi / wheelLetters.length;
      for (int i = 0; i < wheelLetters.length; i++) {
        double angle = i * step - pi / 2;
        double x = centerX + wheelRadius * cos(angle);
        double y = centerY + wheelRadius * sin(angle);
        letterPositions.add(Offset(x, y));
      }
    }
    return Scaffold(
      backgroundColor: kBackgroundColor, 
      appBar: AppBar(
        title: const Text("Kelime Oyunu"),
        actions: [
          Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(color: Colors.orange.withAlpha(50), borderRadius: BorderRadius.circular(20)),
            child: Row(children: [
              const Icon(Icons.star_rounded, color: Colors.orange, size: 20), 
              const SizedBox(width: 4),               
              
              StreamBuilder<DocumentSnapshot>(
                stream: DatabaseService().getUserStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.data() != null) {
                    Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;
                    _currentDbScore = data['score'] ?? 0; // Puanı güncelle
                    return Text("$_currentDbScore", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange));
                  }
                  return const Text("...", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange));
                },
              ),
              // ----------------------------------------------
              
            ]),
          ))
        ]
      ),
      body: Stack(
        children: [
          // --- BULMACA ALANI ---
          Positioned(
            top: 0, 
            left: 0, 
            right: 0, 
            height: size.height * 0.55, 
            child: InteractiveViewer(
              minScale: 0.5, 
              maxScale: 2.0, 
              boundaryMargin: const EdgeInsets.all(double.infinity), 
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 600, 
                  height: 600, 
                  child: CustomPaint(
                    painter: CrosswordGridPainter(
                      level: currentLevel!, 
                      foundWords: foundWords, 
                      revealedCells: revealedCells
                    )
                  )
                ),
              )
            )
          ),
          
          CustomPaint(painter: LinePainter(letterPositions: letterPositions, selectedIndexes: selectedIndexes, currentDragPosition: currentDragPosition), size: Size.infinite),
          
          GestureDetector(onPanStart: _onPanStart, onPanUpdate: _onPanUpdate, onPanEnd: _onPanEnd, child: Container(color: Colors.transparent, child: Stack(children: [
              // --- ORTADAKİ GRİ ALAN ve KARIŞTIRMA BUTONU ---
              Positioned(
                left: centerX - wheelRadius - (letterSize/2 + 10), 
                top: centerY - wheelRadius - (letterSize/2 + 10), 
                child: Container(
                  width: (wheelRadius + (letterSize/2 + 10)) * 2, 
                  height: (wheelRadius + (letterSize/2 + 10)) * 2, 
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.withAlpha(30)),
                  child: Center(
                    child: IconButton(
                      icon: const Icon(Icons.shuffle, size: 32, color: Colors.grey),
                      onPressed: _onShuffle,
                    ),
                  ),
                )
              ),
              
              // --- HARFLER ---
              ...List.generate(wheelLetters.length, (index) { 
                bool isSelected = selectedIndexes.contains(index); 
                return Positioned(
                  left: letterPositions[index].dx - (letterSize/2), 
                  top: letterPositions[index].dy - (letterSize/2), 
                  child: Container(
                    width: letterSize, 
                    height: letterSize, 
                    decoration: BoxDecoration(color: isSelected ? kGame4Color : Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 5, offset: const Offset(0, 3))]), 
                    alignment: Alignment.center, 
                    child: Text(wheelLetters[index], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : kTextColor))
                  )
                ); 
              }),
              
              // --- SEÇİLEN KELİME GÖSTERGESİ ---
              if (selectedIndexes.isNotEmpty) Positioned(top: centerY - 150, left: 0, right: 0, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(color: kPrimaryColor, borderRadius: BorderRadius.circular(20)), child: Text(selectedIndexes.map((i) => wheelLetters[i]).join(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)))))
          ]))),

          // --- İPUCU BUTONU ---
          Positioned(
            bottom: 40, right: 30,
            child: FloatingActionButton(onPressed: _useHint, backgroundColor: Colors.white, child: const Icon(Icons.lightbulb, color: Colors.orange, size: 30)),
          ),
          Positioned(bottom: 20, right: 35, child: Text("-$hintCost", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])))
        ],
      ),
    );
  }
}

// --- PAINTERS (Dokunulmadı - Aynen Korundu) ---
class CrosswordGridPainter extends CustomPainter {
  final GameLevel level; final List<String> foundWords; final Set<String> revealedCells; final double cellSize = 40.0;
  CrosswordGridPainter({required this.level, required this.foundWords, required this.revealedCells});
  
  @override
  void paint(Canvas canvas, Size size) {
    double offsetX = 0; 
    double offsetY = 10; 

    final paintBorder = Paint()..color = Colors.grey..style = PaintingStyle.stroke..strokeWidth = 1.0;
    final paintFill = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final paintFoundFill = Paint()..color = kGame1Color..style = PaintingStyle.fill;
    final textStyleFound = const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold);
    final textStyleHint = const TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.bold); 

    Map<String, Map<String, dynamic>> gridState = {};
    for (var wordLoc in level.words) {
      bool isWordFound = foundWords.contains(wordLoc.word);
      List<String> chars = wordLoc.word.split('');
      for (int i = 0; i < chars.length; i++) {
        int row = wordLoc.startRow + (wordLoc.direction == Axis.vertical ? i : 0);
        int col = wordLoc.startCol + (wordLoc.direction == Axis.horizontal ? i : 0);
        String key = "${row}_$col";
        if (!gridState.containsKey(key)) { gridState[key] = {'char': chars[i], 'isFound': false, 'isRevealed': false}; }
        if (isWordFound) gridState[key]!['isFound'] = true;
        if (revealedCells.contains(key)) gridState[key]!['isRevealed'] = true;
      }
    }
    gridState.forEach((key, cellData) {
      var parts = key.split('_'); int r = int.parse(parts[0]); int c = int.parse(parts[1]);
      double x = offsetX + c * cellSize; double y = offsetY + r * cellSize;
      Rect rect = Rect.fromLTWH(x, y, cellSize, cellSize);
      bool showGreen = cellData['isFound']; bool showChar = cellData['isFound'] || cellData['isRevealed'];
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), showGreen ? paintFoundFill : paintFill);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), paintBorder);
      if (showChar) {
        TextSpan span = TextSpan(style: showGreen ? textStyleFound : textStyleHint, text: cellData['char']);
        TextPainter tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
        tp.layout(); tp.paint(canvas, Offset(x + (cellSize - tp.width) / 2, y + (cellSize - tp.height) / 2));
      }
    });
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class LinePainter extends CustomPainter {
  final List<Offset> letterPositions; final List<int> selectedIndexes; final Offset? currentDragPosition;
  LinePainter({required this.letterPositions, required this.selectedIndexes, this.currentDragPosition});
  @override
  void paint(Canvas canvas, Size size) {
    if (selectedIndexes.isEmpty) return;
    final paint = Paint()..color = kGame4Color..strokeWidth = 10..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    for (int i = 0; i < selectedIndexes.length - 1; i++) {
      canvas.drawLine(letterPositions[selectedIndexes[i]], letterPositions[selectedIndexes[i + 1]], paint);
    }
    if (currentDragPosition != null) canvas.drawLine(letterPositions[selectedIndexes.last], currentDragPosition!, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}