// lib/views/auth/auth_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/app_theme.dart';

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = context.read<AuthViewModel>();
    final success = await vm.authenticate(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
    );
    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo / Header
                    const Icon(Icons.account_balance_wallet_rounded,
                        size: 72, color: Colors.white),
                    const SizedBox(height: 12),
                    const Text(
                      'FinançasPro',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Text(
                      'Controle Financeiro Pessoal',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    const SizedBox(height: 40),

                    // Card Form
                    Card(
                      elevation: 16,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Mode Selector
                              Row(
                                children: [
                                  Expanded(
                                    child: _ModeButton(
                                      label: 'Entrar',
                                      isActive: vm.isLogin,
                                      onTap: () {
                                        if (!vm.isLogin) vm.toggleAuthMode();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _ModeButton(
                                      label: 'Cadastrar',
                                      isActive: !vm.isLogin,
                                      onTap: () {
                                        if (vm.isLogin) vm.toggleAuthMode();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Name field (register only)
                              if (!vm.isLogin) ...[
                                TextFormField(
                                  controller: _nameController,
                                  decoration: AppTheme.inputDecoration(
                                    'Nome completo',
                                    Icons.person_outline,
                                  ),
                                  validator: (v) =>
                                      v == null || v.isEmpty ? 'Informe seu nome' : null,
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Email
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: AppTheme.inputDecoration(
                                  'E-mail',
                                  Icons.email_outlined,
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Informe o e-mail';
                                  if (!v.contains('@')) return 'E-mail inválido';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: AppTheme.inputDecoration(
                                  'Senha',
                                  Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility),
                                    onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Informe a senha';
                                  if (v.length < 6) return 'Mínimo 6 caracteres';
                                  return null;
                                },
                              ),

                              // Error message
                              if (vm.errorMessage.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Colors.red, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          vm.errorMessage,
                                          style: const TextStyle(
                                              color: Colors.red, fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Submit Button
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: vm.isLoading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  child: vm.isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          vm.isLogin ? 'Entrar' : 'Criar Conta',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),

                              if (vm.isLogin) ...[
                                const SizedBox(height: 16),
                                Center(
                                  child: Text(
                                    'Demo: demo@financeiro.com / 123456',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey.shade500),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
