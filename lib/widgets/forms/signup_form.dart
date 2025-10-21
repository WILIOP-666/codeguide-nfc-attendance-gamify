import 'package:flutter/material.dart';

class SignupFormData {
  final String email;
  final String password;
  final String fullName;
  final String studentId;
  final String program;
  final int batch;
  final String role;

  const SignupFormData({
    required this.email,
    required this.password,
    required this.fullName,
    required this.studentId,
    required this.program,
    required this.batch,
    required this.role,
  });
}

class SignupForm extends StatefulWidget {
  final bool isLoading;
  final String? error;
  final Function(SignupFormData data) onSubmit;
  final VoidCallback onClearError;

  const SignupForm({
    super.key,
    required this.isLoading,
    this.error,
    required this.onSubmit,
    required this.onClearError,
  });

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _programController = TextEditingController();
  final _batchController = TextEditingController();
  String _selectedRole = 'student';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _studentIdController.dispose();
    _programController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Full Name Field
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
              enabled: !widget.isLoading,
            ),
            const SizedBox(height: 16),

            // Email Field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              enabled: !widget.isLoading,
            ),
            const SizedBox(height: 16),

            // Password Field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              enabled: !widget.isLoading,
            ),
            const SizedBox(height: 16),

            // Confirm Password Field
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Confirm your password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              enabled: !widget.isLoading,
            ),
            const SizedBox(height: 16),

            // Student ID Field
            TextFormField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: 'Student ID',
                hintText: 'Enter your student ID',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your student ID';
                }
                return null;
              },
              enabled: !widget.isLoading,
            ),
            const SizedBox(height: 16),

            // Role Selection
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                hintText: 'Select your role',
                prefixIcon: Icon(Icons.account_circle_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'owner', child: Text('Owner')),
              ],
              onChanged: widget.isLoading ? null : (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Program Field
            TextFormField(
              controller: _programController,
              decoration: const InputDecoration(
                labelText: 'Program',
                hintText: 'Enter your program (e.g., Computer Science)',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your program';
                }
                return null;
              },
              enabled: !widget.isLoading,
            ),
            const SizedBox(height: 16),

            // Batch Field
            TextFormField(
              controller: _batchController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Batch',
                hintText: 'Enter your batch year',
                prefixIcon: Icon(Icons.date_range_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your batch';
                }
                final batch = int.tryParse(value);
                if (batch == null) {
                  return 'Please enter a valid batch year';
                }
                return null;
              },
              enabled: !widget.isLoading,
            ),
            const SizedBox(height: 24),

            // Error Message
            if (widget.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: widget.onClearError,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            if (widget.error != null) const SizedBox(height: 16),

            // Sign Up Button
            FilledButton(
              onPressed: widget.isLoading ? null : _handleSubmit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Account', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final batch = int.tryParse(_batchController.text);
      if (batch == null) {
        return;
      }

      final formData = SignupFormData(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        studentId: _studentIdController.text.trim(),
        program: _programController.text.trim(),
        batch: batch,
        role: _selectedRole,
      );

      widget.onSubmit(formData);
    }
  }
}