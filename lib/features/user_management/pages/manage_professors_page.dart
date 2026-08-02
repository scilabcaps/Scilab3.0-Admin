import 'package:flutter/material.dart';
import '../controllers/user_controller.dart';
import '../models/user_model.dart';
import '../../../core/utils/app_dialog.dart';

class ManageProfessorsPage extends StatefulWidget {
  const ManageProfessorsPage({super.key});

  @override
  State<ManageProfessorsPage> createState() => _ManageProfessorsPageState();
}

class _ManageProfessorsPageState extends State<ManageProfessorsPage> {
  final UserController _controller = UserController();
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isCreating = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _controller.loadProfessors();
  }

  @override
  void dispose() {
    _controller.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Manage Professors',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              
              // Create New Professor Account Section
              _buildCreateProfessorSection(theme),
              
              const SizedBox(height: 40),
              
              // Existing Professors Section
              _buildExistingProfessorsSection(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateProfessorSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create New Professor Account',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        controller: _firstNameController,
                        label: 'First Name *',
                        icon: Icons.person_outline,
                        validator: _controller.validateFirstName,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildFormField(
                        controller: _lastNameController,
                        label: 'Last Name *',
                        icon: Icons.person_outline,
                        validator: _controller.validateLastName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        controller: _emailController,
                        label: 'Email *',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: _controller.validateEmail,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildFormField(
                        controller: _phoneController,
                        label: 'Phone',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildPasswordField(
                        controller: _passwordController,
                        label: 'Password *',
                        obscureText: _obscurePassword,
                        onTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password *',
                        obscureText: _obscureConfirmPassword,
                        onTap: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Create Professor Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: onTap,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: _controller.validatePassword,
    );
  }

  Widget _buildExistingProfessorsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Existing Professors',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildProfessorsTable(theme),
        ],
      ),
    );
  }

  Widget _buildProfessorsTable(ThemeData theme) {
    return Column(
      children: [
        _buildTableHeader(theme),
        if (_controller.professors.isEmpty)
          _buildEmptyState()
        else
          ..._controller.professors.map((professor) => _buildProfessorRow(professor, theme)),
      ],
    );
  }

  Widget _buildTableHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 4, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 4, child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No professors found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessorRow(User professor, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey[300]!),
          right: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              professor.fullName,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              professor.email,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                  onPressed: () => _showEditDialog(professor),
                ),
                IconButton(
                  icon: Icon(
                    professor.isBanned ? Icons.restore : Icons.block,
                    color: professor.isBanned ? Colors.green : Colors.red,
                  ),
                  onPressed: () async {
                    if (professor.isBanned) {
                      final confirmed = await AppDialog.showConfirmDialog(
                        context: context,
                        title: 'Unban User',
                        content: 'Are you sure you want to unban ${professor.fullName}?',
                        icon: Icons.restore,
                        confirmColor: Colors.green,
                      );
                      if (confirmed == true) {
                        _controller.unbanUser(professor.userId, 'professor');
                      }
                    } else {
                      final confirmed = await AppDialog.showConfirmDialog(
                        context: context,
                        title: 'Ban User',
                        content: 'Are you sure you want to ban ${professor.fullName}?',
                        icon: Icons.block,
                        confirmColor: Colors.red,
                      );
                      if (confirmed == true) {
                        _controller.banUser(professor.userId, 'professor');
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final passwordMatchError = _controller.validatePasswordMatch(
        _passwordController.text,
        _confirmPasswordController.text,
      );
      
      if (passwordMatchError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(passwordMatchError)),
        );
        return;
      }

      setState(() {
        _isCreating = true;
      });

      final success = await _controller.createUser(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _passwordController.text,
        userType: 'professor',
      );

      setState(() {
        _isCreating = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Professor account created successfully')),
        );

        // Clear form
        _formKey.currentState!.reset();
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
      }
    }
  }

  void _showEditDialog(User professor) {
    final editFirstNameController = TextEditingController(text: professor.firstName);
    final editLastNameController = TextEditingController(text: professor.lastName);
    final editEmailController = TextEditingController(text: professor.email);
    final editPhoneController = TextEditingController(text: professor.phone ?? '');
    final editFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Professor'),
          content: SizedBox(
            width: 600,
            child: Form(
              key: editFormKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            controller: editFirstNameController,
                            label: 'First Name *',
                            icon: Icons.person_outline,
                            validator: _controller.validateFirstName,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            controller: editLastNameController,
                            label: 'Last Name *',
                            icon: Icons.person_outline,
                            validator: _controller.validateLastName,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            controller: editEmailController,
                            label: 'Email *',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: _controller.validateEmail,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFormField(
                            controller: editPhoneController,
                            label: 'Phone',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (_) => null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isUpdating
                  ? null
                  : () async {
                      if (editFormKey.currentState!.validate()) {
                        setState(() {
                          _isUpdating = true;
                        });

                        final updatedUser = professor.copyWith(
                          firstName: editFirstNameController.text,
                          lastName: editLastNameController.text,
                          email: editEmailController.text,
                          phone: editPhoneController.text.isEmpty
                              ? null
                              : editPhoneController.text,
                        );

                        final success = await _controller.updateUser(updatedUser);

                        setState(() {
                          _isUpdating = false;
                        });

                        if (success) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Professor updated successfully')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to update professor')),
                          );
                        }
                      }
                    },
              child: _isUpdating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
