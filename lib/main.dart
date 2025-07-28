import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wasil_shopping/core/config/firebase_core.dart';
import 'package:wasil_shopping/core/config/app_config.dart';
import 'package:wasil_shopping/core/router/app_router.dart';
import 'package:wasil_shopping/features/auth/bloc/auth_bloc.dart';
import 'package:wasil_shopping/features/auth/bloc/auth_event.dart';
import 'package:wasil_shopping/features/cart/bloc/cart_bloc.dart';
import 'package:wasil_shopping/features/products/bloc/product_bloc.dart';
import 'package:wasil_shopping/features/theme/bloc/theme_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthBloc()..add(AuthCheck())),
        BlocProvider(create: (context) => ProductBloc()),
        BlocProvider(create: (context) => CartBloc()),
        BlocProvider(create: (context) => ThemeBloc()),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            title: AppConfig.title,
            theme: AppConfig.lightTheme,
            darkTheme: AppConfig.darkTheme,
            themeMode: themeState.themeMode,
            debugShowCheckedModeBanner: AppConfig.debugShowCheckedModeBanner,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
