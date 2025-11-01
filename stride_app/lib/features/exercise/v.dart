import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_app/features/exercise/vm.dart';
import 'package:stride_core/controllers/auth_state_controller.dart';
import 'package:stride_core/models/exercise_m.dart';

class ExerciseV extends StatefulWidget {
  const ExerciseV({super.key});

  @override
  State<ExerciseV> createState() => _ExerciseVState();
}

class _ExerciseVState extends State<ExerciseV> {
  @override
  void initState() {
    super.initState();
    // Initialize exercises on page load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = context.read<AuthStateController>();
      final userId = authController.user?.id;

      if (userId != null) {
        final exerciseVM = context.read<ExerciseVM>();
        exerciseVM.initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExerciseVM>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises & Brain Games'),
        centerTitle: false,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.hasError
          ? _buildErrorState(vm)
          : _buildContent(vm),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: vm.isLoading ? null : () => _showGenerateDialog(context, vm),
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Generate Activities'),
      ),
    );
  }

  Widget _buildErrorState(ExerciseVM vm) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            vm.errorMessage ?? 'An error occurred',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              vm.clearError();
              vm.loadExercises();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ExerciseVM vm) {
    // Show generated exercises selection if available
    if (vm.hasGeneratedExercises) {
      return _buildExerciseSelection(vm);
    }

    // Show pending and completed exercises
    return RefreshIndicator(
      onRefresh: () => vm.loadExercises(),
      child: CustomScrollView(
        slivers: [
          // Pending Exercises Section
          if (vm.pendingExercises.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Pending Activities',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final exercise = vm.pendingExercises[index];
                return _buildExerciseCard(
                  exercise: exercise,
                  isPending: true,
                  onTap: () => _showExerciseDetails(context, exercise, vm),
                );
              }, childCount: vm.pendingExercises.length),
            ),
          ],

          // Completed Exercises Section
          if (vm.completedExercises.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Completed Activities (Last 30 Days)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final exercise = vm.completedExercises[index];
                return _buildExerciseCard(
                  exercise: exercise,
                  isPending: false,
                  onTap: () => _showExerciseDetails(context, exercise, vm),
                );
              }, childCount: vm.completedExercises.length),
            ),
          ],

          // Empty state
          if (vm.pendingExercises.isEmpty && vm.completedExercises.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No exercises yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Generate your first exercise plan!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseSelection(ExerciseVM vm) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose an Activity',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Select one activity to add to your pending list',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: vm.generatedExercises.length,
            itemBuilder: (context, index) {
              final exercise = vm.generatedExercises[index];
              return _buildGeneratedExerciseCard(
                exercise: exercise,
                onSelect: () async {
                  await vm.selectExercise(exercise);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${exercise.title} added to pending'),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                vm.discardGeneratedExercises();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Activities discarded')),
                );
              },
              child: const Text('Discard All'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneratedExerciseCard({
    required ExerciseModel exercise,
    required VoidCallback onSelect,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exercise.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildDifficultyChip(exercise.difficulty),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                exercise.description,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildInfoChip(
                    icon: Icons.category,
                    label: exercise.exerciseType.name,
                  ),
                  if (exercise.durationMinutes != null)
                    _buildInfoChip(
                      icon: Icons.timer,
                      label: '${exercise.durationMinutes} min',
                    ),
                  if (exercise.sets != null && exercise.repetitions != null)
                    _buildInfoChip(
                      icon: Icons.repeat,
                      label: '${exercise.sets}x${exercise.repetitions}',
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onSelect,
                  icon: const Icon(Icons.add),
                  label: const Text('Select This Activity'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard({
    required ExerciseModel exercise,
    required bool isPending,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isPending ? Colors.blue : Colors.green,
          child: Icon(
            isPending ? Icons.pending_actions : Icons.check_circle,
            color: Colors.white,
          ),
        ),
        title: Text(
          exercise.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              exercise.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildDifficultyChip(exercise.difficulty),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    exercise.exerciseType.name,
                    style: const TextStyle(fontSize: 11),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildDifficultyChip(DifficultyLevel difficulty) {
    Color color;
    switch (difficulty) {
      case DifficultyLevel.beginner:
        color = Colors.green;
      case DifficultyLevel.intermediate:
        color = Colors.orange;
      case DifficultyLevel.advanced:
        color = Colors.red;
    }

    return Chip(
      label: Text(
        difficulty.name,
        style: const TextStyle(fontSize: 11, color: Colors.white),
      ),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
    );
  }

  void _showGenerateDialog(BuildContext context, ExerciseVM vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Activities'),
        content: const Text(
          'This will generate 2-3 personalized exercises and brain games based on your profile and assessment history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await vm.generateExercises();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Exercises generated! Select one to continue.',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _showExerciseDetails(
    BuildContext context,
    ExerciseModel exercise,
    ExerciseVM vm,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return ExerciseDetailsSheet(
            exercise: exercise,
            scrollController: scrollController,
            onComplete: exercise.isPending
                ? () async {
                    await vm.completeExercise(exercise);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${exercise.title} completed!')),
                      );
                    }
                  }
                : null,
            onDelete: () async {
              await vm.deleteExercise(exercise.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${exercise.title} deleted!')),
                );
              }
            },
          );
        },
      ),
    );
  }
}

// Exercise Details Bottom Sheet
class ExerciseDetailsSheet extends StatelessWidget {
  final ExerciseModel exercise;
  final ScrollController scrollController;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  const ExerciseDetailsSheet({
    super.key,
    required this.exercise,
    required this.scrollController,
    this.onComplete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView(
        controller: scrollController,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Text(
            exercise.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            exercise.description,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),

          // Exercise details
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildDetailChip(
                icon: Icons.category,
                label: exercise.exerciseType.name,
              ),
              _buildDifficultyChip(exercise.difficulty),
              if (exercise.durationMinutes != null)
                _buildDetailChip(
                  icon: Icons.timer,
                  label: '${exercise.durationMinutes} min',
                ),
              if (exercise.sets != null)
                _buildDetailChip(
                  icon: Icons.repeat,
                  label: '${exercise.sets} sets',
                ),
              if (exercise.repetitions != null)
                _buildDetailChip(
                  icon: Icons.format_list_numbered,
                  label: '${exercise.repetitions} reps',
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Instructions
          if (exercise.instructions.isNotEmpty) ...[
            const Text(
              'Instructions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...exercise.instructions.map(
              (instruction) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      child: Text('${instruction.stepNumber}'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        instruction.instruction,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Equipment
          if (exercise.equipmentNeeded.isNotEmpty) ...[
            const Text(
              'Equipment Needed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: exercise.equipmentNeeded
                  .map((eq) => Chip(label: Text(eq)))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Target Muscles
          if (exercise.targetMuscles.isNotEmpty) ...[
            const Text(
              'Target Muscles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: exercise.targetMuscles
                  .map((muscle) => Chip(label: Text(muscle)))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Benefits
          if (exercise.benefits.isNotEmpty) ...[
            const Text(
              'Benefits',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...exercise.benefits.map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 20,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(benefit)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Safety information
          if (exercise.safety != null) ...[
            if (exercise.safety!.warnings.isNotEmpty) ...[
              const Text(
                'Safety Warnings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              ...exercise.safety!.warnings.map(
                (warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(warning)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (exercise.safety!.tips.isNotEmpty) ...[
              const Text(
                'Safety Tips',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...exercise.safety!.tips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb,
                        size: 20,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(tip)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],

          // Modifications
          if (exercise.modifications.isNotEmpty) ...[
            const Text(
              'Modifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...exercise.modifications.map(
              (mod) => Card(
                child: ListTile(
                  leading: const Icon(Icons.tune),
                  title: Text(mod.level),
                  subtitle: Text(mod.description),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Complete button
          if (onComplete != null)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onComplete,
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark as Completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.check_circle),
              label: const Text('Delete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDetailChip({required IconData icon, required String label}) {
    return Chip(avatar: Icon(icon, size: 16), label: Text(label));
  }

  Widget _buildDifficultyChip(DifficultyLevel difficulty) {
    Color color;
    switch (difficulty) {
      case DifficultyLevel.beginner:
        color = Colors.green;
      case DifficultyLevel.intermediate:
        color = Colors.orange;
      case DifficultyLevel.advanced:
        color = Colors.red;
    }

    return Chip(
      label: Text(difficulty.name, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}
