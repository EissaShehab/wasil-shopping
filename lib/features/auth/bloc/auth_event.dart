import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheck extends AuthEvent {}

class AuthLogin extends AuthEvent {
  final String email;
  final String password;

  AuthLogin(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class AuthRegister extends AuthEvent {
  final String email;
  final String password;

  AuthRegister(this.email, this.password);

  @override
  List<Object?> get props => [email, password];
}

class AuthLogout extends AuthEvent {}

class AuthGuestLogin extends AuthEvent {}