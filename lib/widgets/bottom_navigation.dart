import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _currentIndex = 0;

  // Список экранов для отображения
  final List<Widget> _screens = [
    const MainScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: _screens[_currentIndex], // Анимация смены экранов
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD1DC), Color(0xFF66B2A8)], // Нежно-розовый и мятный
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index; // Обновляем индекс текущего экрана
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed, // Равномерное распределение
          selectedItemColor: Colors.black, // Чёрный цвет для выбранных
          unselectedItemColor: const Color(0xFF000000), // Светло-серый для невыбранных
          selectedFontSize: 14,
          unselectedFontSize: 12,
          items: [
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.home, 0),
              label: 'Главная',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.person, 1),
              label: 'Профиль',
            ),
            BottomNavigationBarItem(
              icon: _buildIcon(Icons.settings, 2),
              label: 'Настройки',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, int index) {
    final isSelected = _currentIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(6.0),
      decoration: isSelected
          ? BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD1DC), Color(0xFF66B2A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      )
          : null,
      child: Icon(
        icon,
        size: isSelected ? 30 : 24, // Увеличение размера выбранной иконки
        color: Colors.black, // Чёрный цвет для всех иконок
      ),
    );
  }
}
