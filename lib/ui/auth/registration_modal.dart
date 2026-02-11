import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme.dart';

class RegistrationModal extends StatefulWidget {
  const RegistrationModal({super.key});

  @override
  State<RegistrationModal> createState() => _RegistrationModalState();
}

class _RegistrationModalState extends State<RegistrationModal> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _universityController = TextEditingController(
    text: 'Université de Labé',
  );
  final _licenseController = TextEditingController();
  final _departmentController = TextEditingController();

  String _gender = 'M';
  File? _avatarFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.path != null) {
      setState(() {
        _avatarFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<ChallengeProvider>().signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        gender: _gender,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        university: _universityController.text.trim(),
        license: _licenseController.text.trim(),
        department: _departmentController.text.trim(),
        avatarFile: _avatarFile,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Inscription réussie !")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erreur: ${e.toString()}")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;

    return Dialog(
      backgroundColor: ThemeColors.editorBg(theme),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Créer un compte",
                  style: TextStyle(
                    color: ThemeColors.textBright(theme),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Avatar Selection
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      backgroundImage: _avatarFile != null
                          ? FileImage(_avatarFile!)
                          : null,
                      child: _avatarFile == null
                          ? const Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.white54,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _firstNameController,
                        label: "Prénom",
                        theme: theme,
                        validator: (v) => v!.isEmpty ? "Requis" : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _lastNameController,
                        label: "Nom",
                        theme: theme,
                        validator: (v) => v!.isEmpty ? "Requis" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Sexe",
                            style: TextStyle(
                              color: ThemeColors.textMain(theme),
                              fontSize: 12,
                            ),
                          ),
                          DropdownButton<String>(
                            value: _gender,
                            dropdownColor: ThemeColors.editorBg(theme),
                            isExpanded: true,
                            underline: Container(
                              height: 1,
                              color: Colors.white24,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'M',
                                child: Text(
                                  "Masculin",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'F',
                                child: Text(
                                  "Féminin",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                            onChanged: (v) => setState(() => _gender = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _phoneController,
                        label: "Téléphone (optionnel)",
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _universityController,
                  label: "Université",
                  theme: theme,
                  validator: (v) => v!.isEmpty ? "Requis" : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _departmentController,
                        label: "Département",
                        theme: theme,
                        validator: (v) => v!.isEmpty ? "Requis" : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _licenseController,
                        label: "Licence / Filière",
                        theme: theme,
                        validator: (v) => v!.isEmpty ? "Requis" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _emailController,
                  label: "Email",
                  theme: theme,
                  validator: (v) => v!.contains('@') ? null : "Email invalide",
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _passwordController,
                  label: "Mot de passe",
                  theme: theme,
                  obscureText: true,
                  validator: (v) => v!.length >= 6 ? null : "Min 6 caractères",
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("S'INSCRIRE"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required AppTheme theme,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: ThemeColors.textMain(theme).withValues(alpha: 0.5),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }
}
