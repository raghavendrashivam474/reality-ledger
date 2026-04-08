import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/task_model.dart';
import '../data/local_storage.dart';
import '../data/repository.dart';
import '../data/supabase_repository.dart';
import '../config.dart';


class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  int _estimatedMinutes = 45;
  String _selectedTag = 'STUDY';
  int _selectedDifficulty = 1;
  bool _isNonNegotiable = false;
  final DatabaseRepository _storage = AppConfig.isCloudReady ? SupabaseRepository() : LocalStorage();

  final List<String> _tags = ['STUDY', 'CODING', 'GYM', 'READING', 'WORK'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("NEW TASK"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 500),
        tween: Tween<double>(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                autofocus: true,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "What exactly needs to be done?",
                  hintStyle: TextStyle(color: Colors.white24),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                "ESTIMATED TIME (MINUTES)",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white54,
                    ),
              ),
              Slider(
                value: _estimatedMinutes.toDouble(),
                min: 15,
                max: 240,
                divisions: 15,
                activeColor: Theme.of(context).colorScheme.primary,
                label: '$_estimatedMinutes m',
                onChanged: (val) {
                  setState(() => _estimatedMinutes = val.toInt());
                },
              ),
              Center(
                child: Text(
                  "$_estimatedMinutes minutes",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                "TAG",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white54,
                    ),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _tags.map((tag) {
                  final isSelected = _selectedTag == tag;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTag = tag),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        border: Border.all(color: Colors.white),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              Text(
                "DIFFICULTY",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.white54,
                    ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  _buildDifficultyChip(1, "LOW"),
                  const SizedBox(width: 12),
                  _buildDifficultyChip(2, "MED"),
                  const SizedBox(width: 12),
                  _buildDifficultyChip(3, "HIGH"),
                ],
              ),
              const SizedBox(height: 40),
              // NEW: Non-Negotiable Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isNonNegotiable ? Theme.of(context).colorScheme.secondary.withOpacity(0.1) : Colors.transparent,
                  border: Border.all(color: _isNonNegotiable ? Theme.of(context).colorScheme.secondary : Colors.white10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded, 
                      color: _isNonNegotiable ? Theme.of(context).colorScheme.secondary : Colors.white24
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "NON-NEGOTIABLE",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                          ),
                          Text(
                            "If this fails, the day is lost.",
                            style: TextStyle(fontSize: 12, color: _isNonNegotiable ? Colors.white70 : Colors.white24),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isNonNegotiable,
                      activeColor: Theme.of(context).colorScheme.secondary,
                      onChanged: (val) => setState(() => _isNonNegotiable = val),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () async {
                  if (_titleController.text.trim().isEmpty) return;
  
                  final String uuidBase = DateTime.now().millisecondsSinceEpoch.toString();
  
                  final task = TaskModel(
                    id: uuidBase,
                    title: _titleController.text.trim(),
                    estimatedMinutes: _estimatedMinutes,
                    tag: _selectedTag,
                    createdAt: DateTime.now(),
                    difficulty: _selectedDifficulty,
                    isNonNegotiable: _isNonNegotiable,
                  );
  
                  await _storage.saveTask(task);
                  HapticFeedback.heavyImpact();
                  if (mounted) Navigator.pop(context, true);
                },
                child: const Text(
                  "COMMIT TO REALITY",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDifficultyChip(int level, String label) {
    final isSelected = _selectedDifficulty == level;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDifficulty = level),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white24,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
