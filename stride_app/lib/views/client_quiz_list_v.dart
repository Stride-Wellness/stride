import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stride_core/models/onboarding_quiz_result_m.dart';
import 'package:stride_core/models/question_node_m.dart';
import 'package:stride_core/view_models/client_quiz_list_vm.dart';
import 'package:stride_ui/constants/layout.dart';
import 'package:stride_ui/widgets/button.dart';
import 'package:stride_ui/widgets/list_options.dart';

class ClientQuizListView extends StatefulWidget {
  const ClientQuizListView({super.key});

  @override
  State<ClientQuizListView> createState() => _ClientQuizListViewState();
}

class _ClientQuizListViewState extends State<ClientQuizListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientQuizListViewModel>().loadQuizzes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Quizzes')),
      body: Consumer<ClientQuizListViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const _LoadingWidget();
          }

          if (viewModel.error != null) {
            return _ErrorWidget(error: viewModel.error!);
          }

          if (viewModel.quizzes.isEmpty) {
            return const _EmptyStateWidget();
          }

          return SizedBox(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _QuizListWidget(quizzes: viewModel.quizzes),
                Padding(
                  padding: const EdgeInsets.all(KPadding.pagePadding),
                  child: SizedBox(
                    width: double.infinity,
                    child: Button(
                      varient: ButtonVarient.primary,
                      child: const Text("Checkin"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckinPageView(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CheckinPageView extends StatelessWidget {
  CheckinPageView({super.key});

  final quizQuestions = [
    QuestionOption(
      "How are you feeling today?",
      QuestionType.dropdown,
      dropdownOptions: ["Great", "Good", "Okay", "Bad", "Terrible"],
      fieldKey: "feeling_today",
    ),
    QuestionOption(
      "Anything specific on your mind?",
      QuestionType.longInput,
      fieldKey: "specific_mind",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ClientQuizListViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Check-in Survey')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(KPadding.pagePadding),
          child: Column(
            children: [
              Expanded(
                child: ListOptionsWidget(
                  options: quizQuestions,
                  maxSelected: 1,
                  minSelected: 1,
                  isMultiField: true,
                  onSelectionChanged: (value) => {
                    viewModel.updateAnswers(value)
                  },
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Button(varient: ButtonVarient.primary, child: const Text("Submit"), onPressed: () {
                  viewModel.submitQuiz();
                  Navigator.pop(context);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorWidget extends StatelessWidget {
  final String error;

  const _ErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading quizzes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No quizzes yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Complete your first quiz to see it here',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _QuizListWidget extends StatelessWidget {
  final List<QuizResult> quizzes;

  const _QuizListWidget({required this.quizzes});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quizzes.length,
        itemBuilder: (context, index) {
          return _QuizCard(quiz: quizzes[index]);
        },
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final QuizResult quiz;

  const _QuizCard({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showQuizDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.quiz, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      quiz.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Completed: ${_formatDate(quiz.timestamp.toDate())}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Text(
                '${quiz.answers.length} answers',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuizDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _QuizDetailsSheet(quiz: quiz),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _QuizDetailsSheet extends StatelessWidget {
  final QuizResult quiz;

  const _QuizDetailsSheet({required this.quiz});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          quiz.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Text(
                    'Completed: ${_formatDate(quiz.timestamp.toDate())}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: quiz.answers.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final entry = quiz.answers.entries.elementAt(index);
                  return _QuizAnswerItem(
                    question: entry.key,
                    answer: entry.value,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _QuizAnswerItem extends StatelessWidget {
  final String question;
  final dynamic answer;

  const _QuizAnswerItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _formatAnswer(answer),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _formatAnswer(dynamic answer) {
    if (answer is List) {
      return answer.join(', ');
    }
    return answer.toString();
  }
}
