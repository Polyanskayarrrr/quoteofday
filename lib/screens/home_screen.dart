import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:async';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String _quote = 'Нажмите кнопку для получения случайной цитаты';
  String _author = '';
  bool _isLoading = false;
  bool _isButtonDisabled = false;
  bool _isFavorite = false; // Для отслеживания статуса избранного
  Duration _timeRemaining = const Duration(hours: 6); // Таймер на 6 часов
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadSavedQuote();
    _loadFavoriteStatus();
    _checkQuoteAvailability();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedQuote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userData = await userDoc.get();

    if (userData.exists) {
      setState(() {
        _quote = userData.data()?['savedQuote'] ?? _quote;
        _author = userData.data()?['savedAuthor'] ?? _author;
      });
    }
  }

  Future<void> _saveQuote(String quote, String author) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await userDoc.set({
      'savedQuote': quote,
      'savedAuthor': author,
    }, SetOptions(merge: true));
  }

  Future<void> _loadFavoriteStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userData = await userDoc.get();

    if (userData.exists) {
      setState(() {
        _isFavorite = userData.data()?['isFavorite'] ?? false;
      });
    }
  }

  Future<void> _saveFavoriteStatus(bool isFavorite) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await userDoc.set({
      'isFavorite': isFavorite,
    }, SetOptions(merge: true));
  }

  Future<void> _checkQuoteAvailability() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userData = await userDoc.get();

    if (userData.exists && userData.data()?['lastFetchTime'] != null) {
      final lastFetchTime = userData.data()?['lastFetchTime'].toDate();
      final currentTime = DateTime.now();
      final difference = currentTime.difference(lastFetchTime);

      if (difference.inHours < 6) {
        final remainingTime = Duration(hours: 6) - difference;
        setState(() {
          _isButtonDisabled = true;
          _timeRemaining = remainingTime;
        });
        _startTimer();
      } else {
        setState(() {
          _isButtonDisabled = false;
        });
      }
    } else {
      setState(() {
        _isButtonDisabled = false;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining.inSeconds <= 0) {
        setState(() {
          _isButtonDisabled = false;
          _timer?.cancel();
        });
      } else {
        setState(() {
          _timeRemaining -= const Duration(seconds: 1);
        });
      }
    });
  }

  Future<void> _fetchQuote() async {
    setState(() {
      _isLoading = true;
      _isButtonDisabled = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://zenquotes.io/api/random'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String quote = data[0]['q'];
        final String author = data[0]['a'];

        // Перевод цитаты на русский язык
        final String translatedQuote = await _translateText(quote, 'en', 'ru');
        final String translatedAuthor = await _translateText(author, 'en', 'ru');

        setState(() {
          _quote = translatedQuote;
          _author = translatedAuthor;
          _isFavorite = false;
        });

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
          await userDoc.set({
            'lastFetchTime': DateTime.now(),
            'savedQuote': translatedQuote,
            'savedAuthor': translatedAuthor,
          }, SetOptions(merge: true));
        }

        _timeRemaining = const Duration(hours: 6);
        _startTimer();
      } else {
        setState(() {
          _quote = 'Ошибка при получении цитаты';
        });
      }
    } catch (e) {
      setState(() {
        _quote = 'Ошибка: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _translateText(
      String text, String sourceLang, String targetLang) async {
    final response = await http.get(
      Uri.parse(
          'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$sourceLang&tl=$targetLang&dt=t&q=$text'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data[0][0][0];
    } else {
      throw Exception('Ошибка перевода текста');
    }
  }

  Future<void> _addToFavorites() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null && _quote.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .add({'quote': _quote, 'author': _author, 'timestamp': Timestamp.now()});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Цитата добавлена в избранное')),
        );
        setState(() {
          _isFavorite = true;
        });
        _saveFavoriteStatus(true); // Сохранение состояния избранного
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:' +
        '${minutes.toString().padLeft(2, '0')}:' +
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F6F3), // Мятный фон
      appBar: AppBar(
        backgroundColor: const Color(0xFF66B2A8), // Мятный цвет AppBar
        title: const Text('Цитата дня', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF66B2A8)),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF), // Белый фон
                    borderRadius: BorderRadius.circular(15.0),
                    border: Border.all(color: const Color(0xFF66B2A8), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10.0,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _quote,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF66B2A8), // Мятный цвет
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _author.isNotEmpty ? '- $_author' : '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      IconButton(
                        onPressed: _isFavorite ? null : _addToFavorites,
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.grey,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isButtonDisabled ? null : _fetchQuote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isButtonDisabled
                      ? Colors.grey
                      : const Color(0xFFFFD1DC), // Нежно-розовая кнопка
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30.0, vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  elevation: 5,
                ),
                child: Text(
                  _isButtonDisabled
                      ? 'Подождите: ${_formatDuration(_timeRemaining)}'
                      : 'Получить цитату',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
