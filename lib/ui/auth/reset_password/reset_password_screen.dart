import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../routing/app_router.dart';
import '../../core/branding/brand_scope.dart';
import '../password_recovery_view_model.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    required this.repository,
    required this.initialToken,
    super.key,
  });

  final AuthRepository repository;
  final String initialToken;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final PasswordRecoveryViewModel _viewModel;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken);
    _viewModel = PasswordRecoveryViewModel(widget.repository);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    await _viewModel.resetPassword(
      token: _tokenController.text,
      newPassword: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            if (_viewModel.status == PasswordRecoveryStatus.success) {
              return _ResetSuccess(
                message: _viewModel.message!,
                onBackToLogin: () => context.go(AppRoutes.login),
              );
            }

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: BackButton(
                            onPressed: () => context.canPop()
                                ? context.pop()
                                : context.go(AppRoutes.login),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Icon(
                          Icons.password_outlined,
                          size: 54,
                          color: brand.primaryColor,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Crea una nueva contraseña',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: brand.inkColor,
                              ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Utiliza el token recibido y una contraseña de al menos 8 caracteres.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF6F788A)),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _tokenController,
                          enabled: !_viewModel.isSubmitting,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: const InputDecoration(
                            labelText: 'Token de recuperación',
                            prefixIcon: Icon(Icons.key_outlined),
                          ),
                          validator: (value) => value?.trim().isNotEmpty == true
                              ? null
                              : 'Ingresa el token recibido.',
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          enabled: !_viewModel.isSubmitting,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Nueva contraseña',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) => (value?.length ?? 0) >= 8
                              ? null
                              : 'Usa al menos 8 caracteres.',
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPasswordController,
                          enabled: !_viewModel.isSubmitting,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onFieldSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            labelText: 'Confirmar contraseña',
                            prefixIcon: Icon(Icons.lock_reset_outlined),
                          ),
                          validator: (value) =>
                              value == _passwordController.text
                              ? null
                              : 'Las contraseñas no coinciden.',
                        ),
                        if (_viewModel.status ==
                            PasswordRecoveryStatus.failure) ...[
                          const SizedBox(height: 14),
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _viewModel.message!,
                              key: const Key('reset-password-error'),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _viewModel.isSubmitting ? null : _submit,
                          child: _viewModel.isSubmitting
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Actualizar contraseña'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ResetSuccess extends StatelessWidget {
  const _ResetSuccess({required this.message, required this.onBackToLogin});

  final String message;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Color(0xFF0F9F6E),
              ),
              const SizedBox(height: 20),
              Text(
                'Contraseña actualizada',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(message, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: onBackToLogin,
                child: const Text('Iniciar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
