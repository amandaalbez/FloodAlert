import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  final _nomeFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _senhaFocus = FocusNode();
  final _confirmarSenhaFocus = FocusNode();

  bool _mostrarSenha = false;
  bool _mostrarConfirmarSenha = false;
  bool _aceitouTermos = false;
  bool _carregando = false;

  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,4}$');

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    _nomeFocus.dispose();
    _emailFocus.dispose();
    _senhaFocus.dispose();
    _confirmarSenhaFocus.dispose();
    super.dispose();
  }

  String? _validarNome(String? value) {
    final nome = value?.trim() ?? '';
    if (nome.isEmpty) return 'Informe seu nome';
    if (nome.trim().split(RegExp(r'\s+')).length < 2) {
      return 'Informe nome e sobrenome';
    }
    return null;
  }

  String? _validarEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Informe seu e-mail';
    if (!_emailRegex.hasMatch(email)) return 'E-mail inválido';
    return null;
  }

  String? _validarSenha(String? value) {
    final senha = value ?? '';
    if (senha.isEmpty) return 'Crie uma senha';
    if (senha.length < 6) return 'A senha deve ter ao menos 6 caracteres';
    return null;
  }

  String? _validarConfirmarSenha(String? value) {
    final confirmar = value ?? '';
    if (confirmar.isEmpty) return 'Confirme sua senha';
    if (confirmar != _senhaController.text) return 'As senhas não coincidem';
    return null;
  }

  Future<void> _criarConta() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.lightImpact();
      return;
    }

    if (!_aceitouTermos) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa aceitar os termos de uso.'),
        ),
      );
      return;
    }

    setState(() => _carregando = true);

    try {
      // TODO: substituir pela chamada real à API de cadastro
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cadastro será conectado à API posteriormente.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível criar a conta. Tente novamente.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ---------- Cabeçalho ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 24, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _carregando
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_rounded,
                              color: AppColors.primary,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text('Criar conta', style: textTheme.headlineMedium
                              ?.copyWith(color: AppColors.textPrimary)),
                          const SizedBox(height: 6),
                          Text(
                            'Cadastre-se para receber alertas de '
                            'alagamento na sua região',
                            style: textTheme.bodyMedium,
                          ),

                          const SizedBox(height: 28),

                          Text('Nome completo', style: textTheme.labelLarge),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nomeController,
                            focusNode: _nomeFocus,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            validator: _validarNome,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).requestFocus(_emailFocus),
                            decoration: const InputDecoration(
                              hintText: 'Digite seu nome completo',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Text('E-mail', style: textTheme.labelLarge),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            validator: _validarEmail,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).requestFocus(_senhaFocus),
                            decoration: const InputDecoration(
                              hintText: 'Digite seu e-mail',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Text('Senha', style: textTheme.labelLarge),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _senhaController,
                            focusNode: _senhaFocus,
                            obscureText: !_mostrarSenha,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            validator: _validarSenha,
                            onFieldSubmitted: (_) => FocusScope.of(context)
                                .requestFocus(_confirmarSenhaFocus),
                            decoration: InputDecoration(
                              hintText: 'Crie uma senha',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _mostrarSenha
                                    ? 'Ocultar senha'
                                    : 'Mostrar senha',
                                icon: Icon(
                                  _mostrarSenha
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() => _mostrarSenha = !_mostrarSenha);
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Text('Confirmar senha', style: textTheme.labelLarge),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmarSenhaController,
                            focusNode: _confirmarSenhaFocus,
                            obscureText: !_mostrarConfirmarSenha,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            validator: _validarConfirmarSenha,
                            onFieldSubmitted: (_) => _criarConta(),
                            decoration: InputDecoration(
                              hintText: 'Repita a senha',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _mostrarConfirmarSenha
                                    ? 'Ocultar senha'
                                    : 'Mostrar senha',
                                icon: Icon(
                                  _mostrarConfirmarSenha
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() => _mostrarConfirmarSenha =
                                      !_mostrarConfirmarSenha);
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _aceitouTermos,
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  onChanged: _carregando
                                      ? null
                                      : (value) => setState(
                                          () => _aceitouTermos = value ?? false),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _carregando
                                      ? null
                                      : () => setState(
                                          () => _aceitouTermos = !_aceitouTermos),
                                  child: Text.rich(
                                    TextSpan(
                                      style: textTheme.bodySmall,
                                      children: [
                                        const TextSpan(
                                            text: 'Li e aceito os '),
                                        TextSpan(
                                          text: 'Termos de Uso',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const TextSpan(text: ' e a '),
                                        TextSpan(
                                          text: 'Política de Privacidade',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _carregando ? null : _criarConta,
                              child: _carregando
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text('CRIAR CONTA'),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                Text('Já tem uma conta? ',
                                    style: textTheme.bodySmall),
                                GestureDetector(
                                  onTap: _carregando
                                      ? null
                                      : () => Navigator.of(context).maybePop(),
                                  child: Text(
                                    'Entrar',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}