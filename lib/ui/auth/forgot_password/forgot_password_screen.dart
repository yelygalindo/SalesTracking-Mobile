import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../routing/app_router.dart';
import '../../core/branding/brand_scope.dart';
import '../password_recovery_view_model.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({required this.repository, super.key});

  final AuthRepository repository;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  late final PasswordRecoveryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PasswordRecoveryViewModel(widget.repository);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;
    await _viewModel.requestReset(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final succeeded =
                _viewModel.status == PasswordRecoveryStatus.success;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: succeeded
                      ? _SuccessContent(
                          message: _viewModel.message!,
                          onBackToLogin: () => context.go(AppRoutes.login),
                        )
                      : Form(
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
                              const SizedBox(height: 20),
                              Icon(
                                Icons.mark_email_read_outlined,
                                size: 54,
                                color: brand.primaryColor,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Recupera tu contraseña',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: brand.inkColor,
                                    ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Ingresa tu correo y te enviaremos las instrucciones disponibles para restablecerla.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF6F788A)),
                              ),
                              const SizedBox(height: 28),
                              TextFormField(
                                controller: _emailController,
                                enabled: !_viewModel.isSubmitting,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.email],
                                onFieldSubmitted: (_) => _submit(),
                                decoration: const InputDecoration(
                                  labelText: 'Correo electrónico',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty) {
                                    return 'Ingresa tu correo electrónico.';
                                  }
                                  if (!email.contains('@')) {
                                    return 'Ingresa un correo válido.';
                                  }
                                  return null;
                                },
                              ),
                              if (_viewModel.status ==
                                  PasswordRecoveryStatus.failure) ...[
                                const SizedBox(height: 14),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    _viewModel.message!,
                                    key: const Key('forgot-password-error'),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: _viewModel.isSubmitting
                                    ? null
                                    : _submit,
                                child: _viewModel.isSubmitting
                                    ? const SizedBox.square(
                                        dimension: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Enviar instrucciones'),
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: _viewModel.isSubmitting
                                    ? null
                                    : () =>
                                          context.push(AppRoutes.resetPassword),
                                child: const Text('Ya tengo un token'),
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

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({required this.message, required this.onBackToLogin});

  final String message;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 64,
          color: Color(0xFF0F9F6E),
        ),
        const SizedBox(height: 20),
        Text(
          'Revisa tu correo',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Text(message, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: onBackToLogin,
          child: const Text('Volver al inicio'),
        ),
      ],
    );
  }
}
