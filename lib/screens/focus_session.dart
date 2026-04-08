import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/task_model.dart';
import '../models/session_model.dart';
import '../data/local_storage.dart';
import '../data/repository.dart';
import '../data/supabase_repository.dart';
import '../config.dart';

class FocusSessionScreen extends StatefulWidget {
  final TaskModel task;
  const FocusSessionScreen({super.key, required this.task});

  @override
  State<FocusSessionScreen> createState() => _FocusSessionScreenState();
}

class _FocusSessionScreenState extends State<FocusSessionScreen> with SingleTickerProviderStateMixin {
  late int _secondsLeft;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _timer;
  bool _isRunning = false;
  int _pauseCount = 0;
  
  late DatabaseRepository _storage;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.task.estimatedMinutes * 60;
    _storage = AppConfig.isCloudReady ? SupabaseRepository() : LocalStorage();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      setState(() => _isRunning = true);
      HapticFeedback.mediumImpact();
      WakelockPlus.enable();
      _pulseController.repeat(reverse: true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsLeft > 0) {
          setState(() => _secondsLeft--);
        } else {
          _endSession();
        }
      });
    }
  }

  void _pauseTimer() {
    _timer?.cancel();
    WakelockPlus.disable();
    _pulseController.stop();
    setState(() {
      _isRunning = false;
      _pauseCount++;
      HapticFeedback.selectionClick();
    });
  }

  Future<void> _endSession({String? reason}) async {
    _timer?.cancel();
    WakelockPlus.disable();
    
    final actualFocusSeconds = (widget.task.estimatedMinutes * 60) - _secondsLeft;
    final int baseUuid = DateTime.now().millisecondsSinceEpoch;
    
    final session = SessionModel(
      id: baseUuid.toString(),
      taskId: widget.task.id,
      plannedDurationMinutes: widget.task.estimatedMinutes,
      actualFocusMinutes: (actualFocusSeconds / 60).ceil(),
      pauseCount: _pauseCount,
      date: DateTime.now(),
      abandonReason: reason,
    );
    await _storage.saveSession(session);

    if (_secondsLeft <= 0) {
       final updatedTask = widget.task.copyWith(isCompleted: true);
       await _storage.saveTask(updatedTask);
    }
    
    if (mounted) Navigator.pop(context, true);
  }

  void _handleEarlyExit() {
    if (_secondsLeft <= 0) {
      _endSession();
      return;
    }

    _timer?.cancel();
    WakelockPlus.disable();
    setState(() => _isRunning = false);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "WHY ARE YOU QUITTING?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
            ),
            const SizedBox(height: 10),
            const Text(
              "Most focus leaks happen in the last 20%.",
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            _buildReasonButton("SOCIAL MEDIA / DISTRACTION"),
            const SizedBox(height: 12),
            _buildReasonButton("EMERGENCY / CALL"),
            const SizedBox(height: 12),
            _buildReasonButton("JUST QUITTING"),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _toggleTimer(); // Resume
              },
              child: const Text("CONTINUE DEEP WORK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonButton(String reason) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white10,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onPressed: () {
        Navigator.pop(context); // Close bottom sheet
        _endSession(reason: reason);
      },
      child: Text(reason, style: const TextStyle(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    String minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    String seconds = (_secondsLeft % 60).toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("FOCUS ENGINE"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleEarlyExit,
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height - AppBar().preferredSize.height - 50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Text(
                  "$minutes:$seconds",
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 80,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const Spacer(),
              Center(
                child: Text(
                  "DEEP WORK",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                    color: _isRunning ? Theme.of(context).colorScheme.primary : Colors.white54,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  widget.task.title,
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
              const SizedBox(height: 40),
              // Gauge Visualization
              Center(
                child: Column(
                  children: [
                    Text(
                      "INTENSITY",
                      style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 200,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (_secondsLeft / (widget.task.estimatedMinutes * 60)).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (_pauseCount > 0 && !_isRunning)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      "You've paused $_pauseCount times.\nFocus leaking?",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 40.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRunning ? Colors.white : Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isRunning ? _pauseTimer : _toggleTimer,
                  child: Text(
                    _isRunning ? "PAUSE ENGINE" : "START ENGINE",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
