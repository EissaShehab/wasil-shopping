// lib/features/theme/bloc/theme_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ThemeEvent {}

class ToggleTheme extends ThemeEvent {}

class ThemeState {
  final ThemeMode themeMode;
  ThemeState(this.themeMode);
}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(ThemeState(ThemeMode.system)) {
    on<ToggleTheme>((event, emit) {
      final newMode = state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      emit(ThemeState(newMode));
    });
  }
}