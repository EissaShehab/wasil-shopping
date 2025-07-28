// lib/features/profile/views/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wasil_shopping/core/utils/toast_utils.dart';
import 'package:wasil_shopping/features/auth/bloc/auth_bloc.dart';
import 'package:wasil_shopping/features/auth/bloc/auth_event.dart';
import 'package:wasil_shopping/features/auth/bloc/auth_state.dart';
import 'package:wasil_shopping/features/theme/bloc/theme_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState is AuthAuthenticated
                              ? 'User Information'
                              : 'Guest Mode',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 10),
                        if (authState is AuthAuthenticated)
                          ListTile(
                            leading: Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            title: Text(
                              authState.user.email ?? 'No Email',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          )
                        else
                          ListTile(
                            leading: Icon(
                              Icons.person_off,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            title: Text(
                              'Sign in to access your profile',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  child: ListTile(
                    leading: Icon(
                      Icons.brightness_6,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    title: Text(
                      'Dark Mode',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    trailing: BlocBuilder<ThemeBloc, ThemeState>(
                      builder: (context, themeState) {
                        return Switch(
                          value: themeState.themeMode == ThemeMode.dark,
                          onChanged: (value) {
                            context.read<ThemeBloc>().add(ToggleTheme());
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (authState is AuthAuthenticated)
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthLogout());
                        ToastUtils.showToast('Logged out successfully');
                        context.go('/main?index=0');
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                else
                  Center(
                    child: ElevatedButton(
                      onPressed: () => context.go('/auth'),
                      child: const Text('Sign In'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
