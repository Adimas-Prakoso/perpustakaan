import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:perpustakaan/services/user_preferences.dart';
import 'package:perpustakaan/models/user_model.dart';
import 'package:perpustakaan/services/database_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  UserModel? _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = await UserPreferences.getUser();
    if (user != null) {
      setState(() {
        _user = user;
        _nameController = TextEditingController(text: user.name);
      });
    }
  }

  Future<void> _updateName(String newName) async {
    if (_user?.email == null || newName.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final result =
          await DatabaseService.updateName(_user!.email, newName.trim());

      if (result['success']) {
        final updatedUser = UserModel(
          name: newName.trim(),
          email: _user!.email,
          nik: _user!.nik,
        );
        await UserPreferences.saveUser(updatedUser);
        setState(() => _user = updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan saat memperbarui nama'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showEditNameDialog() {
    showDialog(
      context: context,
      barrierDismissible: !_isLoading,
      builder: (context) => AlertDialog(
        title: const Text('Edit Nama'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nama',
            border: OutlineInputBorder(),
            hintText: 'Masukkan nama baru',
          ),
          enabled: !_isLoading,
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    Navigator.pop(context);
                    await _updateName(_nameController.text);
                  },
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    bool isEditable = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isEditable)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: _isLoading ? null : _showEditNameDialog,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        elevation: 0,
      ),
      body: _user == null
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Colors.white,
                  ],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: FadeInDown(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                _user!.name.isNotEmpty
                                    ? _user!.name[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 36,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInLeft(
                      child: _buildInfoItem(
                        label: 'Nama',
                        value: _user!.name,
                        isEditable: true,
                      ),
                    ),
                    FadeInRight(
                      child: _buildInfoItem(
                        label: 'NIK',
                        value: _user!.nik,
                      ),
                    ),
                    FadeInLeft(
                      child: _buildInfoItem(
                        label: 'Email',
                        value: _user!.email,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
