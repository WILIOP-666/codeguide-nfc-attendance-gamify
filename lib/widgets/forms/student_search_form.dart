import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_attendance_gamify/data/models/user_profile.dart';
import 'package:nfc_attendance_gamify/features/attendance/providers/attendance_provider.dart';

class StudentSearchForm extends ConsumerStatefulWidget {
  final Function(String studentId, String studentName) onStudentSelected;
  final bool enabled;

  const StudentSearchForm({
    super.key,
    required this.onStudentSelected,
    this.enabled = true,
  });

  @override
  ConsumerState<StudentSearchForm> createState() => _StudentSearchFormState();
}

class _StudentSearchFormState extends ConsumerState<StudentSearchForm> {
  final _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Field
        TextFormField(
          controller: _searchController,
          enabled: widget.enabled && !_isSearching,
          decoration: InputDecoration(
            hintText: 'Search by name, student ID, or email',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: 12),

        // Search Results
        if (_isSearching)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_searchResults.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final student = _searchResults[index];
                return _StudentTile(
                  student: student,
                  onTap: () => widget.onStudentSelected(student.id, student.fullName),
                );
              },
            ),
          )
        else if (_searchController.text.isNotEmpty && _searchResults.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_off,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'No students found',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _onSearchChanged(String query) {
    if (query.length < 2) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final results = await ref.read(attendanceProvider.notifier).searchStudents(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      // Handle error silently or show message
      setState(() {
        _searchResults.clear();
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults.clear();
    });
  }
}

class _StudentTile extends StatelessWidget {
  final UserProfile student;
  final VoidCallback onTap;

  const _StudentTile({
    required this.student,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          student.fullName.isNotEmpty
              ? student.fullName[0].toUpperCase()
              : 'S',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(
        student.fullName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ID: ${student.studentId}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            '${student.program} • Batch ${student.batch}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}