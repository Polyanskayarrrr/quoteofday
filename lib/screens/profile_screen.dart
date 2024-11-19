import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  DateTime? _selectedDate;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _selectedDate = data['birthDate'] != null
              ? DateFormat("dd-MM-yyyy").parse(data['birthDate'])
              : null;
          _birthDateController.text = _selectedDate != null
              ? DateFormat("dd-MM-yyyy").format(_selectedDate!)
              : '';
        });
      }
    }
  }

  Future<void> _saveProfileData() async {
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'name': _nameController.text,
          'birthDate': _selectedDate != null
              ? DateFormat("dd-MM-yyyy").format(_selectedDate!)
              : '',
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Данные успешно сохранены")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка при сохранении данных: $e")),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale("ru"),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _birthDateController.text = DateFormat("dd-MM-yyyy").format(_selectedDate!);
      });
    }
  }

  Future<void> _deleteFavorite(String docId) async {
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('favorites')
            .doc(docId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Цитата удалена из избранного")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка при удалении цитаты: $e")),
        );
      }
    }
  }

  Widget _buildFavoriteQuotesList() {
    if (user == null) return const Center(child: Text("Вы не авторизованы"));
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('favorites')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final quotes = snapshot.data!.docs;
        if (quotes.isEmpty) {
          return const Center(child: Text("У вас нет избранных цитат"));
        }
        return ListView.builder(
          itemCount: quotes.length,
          itemBuilder: (context, index) {
            final quoteData = quotes[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
              child: ListTile(
                title: Text(quoteData['quote']),
                subtitle: Text(quoteData['author']),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteFavorite(quoteData.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F6F3), // Мятный фон
      appBar: AppBar(
        backgroundColor: const Color(0xFF66B2A8), // Мятный цвет AppBar
        title: const Text('Профиль', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 75.0,
              backgroundImage: NetworkImage('https://filed8-15.my.mail.ru/pic?url=https%3A%2F%2Fcontent-21.foto.my.mail.ru%2Fmail%2Fsonya.kot.07%2F_musicplaylistcover%2Fi-6.jpg&mw=&mh=&sig=126519dd1ba9c06f27413f46fd10f215'),
            ),
            const SizedBox(height: 20),
            _buildTextField(_nameController, 'Имя'),
            const SizedBox(height: 16),
            _buildDateField(context),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfileData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD1DC), // Нежно-розовая кнопка
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
              ),
              child: const Text(
                'Сохранить',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Избранные цитаты',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF66B2A8)),
            ),
            const SizedBox(height: 10),
            Container(
              height: 300, // Установите высоту ListView
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: const Color(0xFF66B2A8), width: 2),
              ),
              child: _buildFavoriteQuotesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {List<TextInputFormatter>? inputFormatters,
        TextInputType? keyboardType,
        IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF66B2A8)), // Мятный цвет текста
          prefixIcon: icon != null
              ? Icon(icon, color: const Color(0xFF66B2A8)) // Мятный цвет иконки
              : null,
          filled: true,
          fillColor: const Color(0xFFFFFFFF), // Белый фон
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF66B2A8), width: 2), // Мятная рамка
          ),
        ),
        inputFormatters: inputFormatters,
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: _birthDateController,
        decoration: InputDecoration(
          labelText: 'Дата рождения',
          labelStyle: const TextStyle(color: Color(0xFF66B2A8)), // Мятный цвет текста
          prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF66B2A8)),
          filled: true,
          fillColor: const Color(0xFFFFFFFF), // Белый фон
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF66B2A8), width: 2), // Мятная рамка
          ),
        ),
        readOnly: true,
        onTap: () => _selectDate(context),
      ),
    );
  }
}
