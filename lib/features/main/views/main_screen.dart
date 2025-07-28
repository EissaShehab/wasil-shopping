import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wasil_shopping/widgets/app_bottom_navigation_bar.dart';

class MainScreen extends StatefulWidget {
  final Widget child;

  const MainScreen({super.key, required this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final uri = GoRouter.of(context).routeInformationProvider.value.uri;
    _currentIndex = int.parse(uri.queryParameters['index'] ?? '0');
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    context.go('/main?index=$index');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
