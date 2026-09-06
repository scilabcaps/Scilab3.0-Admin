import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../controllers/user_controller.dart';
import '../models/user_model.dart';
import '../services/user_account_export_service.dart';
import '../services/user_account_file_writer.dart';
import '../../../core/utils/app_dialog.dart';

class ManageStudentsPage extends StatefulWidget {
  const ManageStudentsPage({super.key});

  @override
  State<ManageStudentsPage> createState() => _ManageStudentsPageState();
}

class _ManageStudentsPageState extends State<ManageStudentsPage> {
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
  bool _isExporting = false;
  int _currentPage = 1;
  static const int _pageSize = 10;

  List<User> get _visibleStudents {
    final page = _totalPages == 0
        ? 1
        : _currentPage.clamp(1, _totalPages) as int;
    final start = (page - 1) * _pageSize;
    if (start >= _controller.students.length) return const [];
    final end = (start + _pageSize).clamp(0, _controller.students.length) as int;
    return _controller.students.sublist(start, end);
  }

  int get _totalPages => (_controller.students.length / _pageSize).ceil();

  @override
  void initState() {
    super.initState();
    _controller.loadStudents();
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

  Future<void> _exportReport(String format) async {
    if (_isExporting) return;
    final generatedAt = DateTime.now();
    setState(() => _isExporting = true);
    try {
      final users = _controller.students;
      if (users.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No student accounts found.'),
        ));
        return;
      }
      final exporter = UserAccountExportService();
      final bytes = format == 'xlsx'
          ? exporter.generateExcel(
              users: users, role: 'Student', generatedAt: generatedAt)
          : await exporter.generatePdf(
              users: users, role: 'Student', generatedAt: generatedAt);
      if (!mounted) return;
      final stamp = generatedAt.toIso8601String().replaceAll(':', '-');
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Student Accounts Report',
        fileName: 'student_accounts_$stamp.$format',
        type: FileType.custom,
        allowedExtensions: [format],
        bytes: bytes,
      );
      if (kIsWeb) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Download started: ${users.length} accounts.'),
        ));
        return;
      }
      if (path == null) return;
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        await writeUserAccountFile(path, bytes);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Saved ${users.length} accounts to $path'),
      ));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not generate report: $error'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Manage Students',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  _buildReportButton(),
                ],
              ),
              const SizedBox(height: 32),
              
              // Create New Student Account Section
              _buildCreateStudentSection(theme),
              
              const SizedBox(height: 40),
              
              // Existing Students Section
              _buildExistingStudentsSection(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportButton() {
    return PopupMenuButton<String>(
      enabled: !_isExporting,
      tooltip: 'Export student accounts',
      onSelected: _exportReport,
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'xlsx', child: Text('Excel (.xlsx)')),
        PopupMenuItem(value: 'pdf', child: Text('PDF (.pdf)')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isExporting
              ? Colors.grey.shade200
              : const Color(0xFF31CB00),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(_isExporting ? 'Generating report...' : 'Generate Report',
                style: TextStyle(
                    color: _isExporting ? Colors.grey.shade700 : Colors.white,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateStudentSection(ThemeData theme) {
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
          const Text(
            'Create New Student Account',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
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
                    const SizedBox(width: 16),
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
                const SizedBox(height: 16),
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFormField(
                        controller: _phoneController,
                        label: 'Phone',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (_) => null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                    const SizedBox(width: 16),
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
                // Error Message
                if (_controller.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _controller.errorMessage!,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                            'Create Student Account',
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
        ),
        filled: true,
        fillColor: Colors.grey[50],
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
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: _controller.validatePassword,
    );
  }

  Widget _buildExistingStudentsSection(ThemeData theme) {
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
          const Text(
            'Existing Students',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStudentsTable(theme),
        ],
      ),
    );
  }

  Widget _buildStudentsTable(ThemeData theme) {
    return Column(
      children: [
        _buildTableHeader(theme),
        if (_controller.students.isEmpty)
          _buildEmptyState()
        else
          ..._visibleStudents.map((student) => _buildStudentRow(student, theme)),
        if (_totalPages > 1) _buildAccountPagination(),
      ],
    );
  }

  Widget _buildAccountPagination() {
    final page = _currentPage.clamp(1, _totalPages) as int;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page $page of $_totalPages (${_controller.students.length} total)',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          Row(
            children: [
              IconButton(
                onPressed: page > 1
                    ? () => setState(() => _currentPage = page - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous page',
              ),
              IconButton(
                onPressed: page < _totalPages
                    ? () => setState(() => _currentPage = page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next page',
              ),
            ],
          ),
        ],
      ),
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
          Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 3, child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
          Expanded(flex: 2, child: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey))),
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
            'No students found',
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

  Widget _buildStudentRow(User student, ThemeData theme) {
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
            flex: 3,
            child: Text(
              student.fullName,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              student.email,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              student.phone ?? 'N/A',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                  onPressed: () => _showEditDialog(student),
                ),
                IconButton(
                  icon: Icon(
                    student.isBanned ? Icons.restore : Icons.block,
                    color: student.isBanned ? Colors.green : Colors.red,
                  ),
                  onPressed: () async {
                    if (student.isBanned) {
                      final confirmed = await AppDialog.showConfirmDialog(
                        context: context,
                        title: 'Unban User',
                        content: 'Are you sure you want to unban ${student.fullName}?',
                        icon: Icons.restore,
                        confirmColor: Colors.green,
                      );
                      if (confirmed == true) {
                        _controller.unbanUser(student.userId, 'student');
                      }
                    } else {
                      final confirmed = await AppDialog.showConfirmDialog(
                        context: context,
                        title: 'Ban User',
                        content: 'Are you sure you want to ban ${student.fullName}?',
                        icon: Icons.block,
                        confirmColor: Colors.red,
                      );
                      if (confirmed == true) {
                        _controller.banUser(student.userId, 'student');
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
        userType: 'student',
      );

      setState(() {
        _isCreating = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student account created successfully')),
        );

        // Clear form
        _formKey.currentState!.reset();
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create student account')),
        );
      }
    }
  }

  void _showEditDialog(User student) {
    final editFirstNameController = TextEditingController(text: student.firstName);
    final editLastNameController = TextEditingController(text: student.lastName);
    final editEmailController = TextEditingController(text: student.email);
    final editPhoneController = TextEditingController(text: student.phone ?? '');
    final editFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Student'),
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

                        final updatedUser = student.copyWith(
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
                            const SnackBar(content: Text('Student updated successfully')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to update student')),
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
