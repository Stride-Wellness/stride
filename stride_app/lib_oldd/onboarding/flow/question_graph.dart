import '../models/nodes.dart';

// Clean unified onboarding graph.
final Map<String, QuestionNode> onboardingGraph = {
  'start': QuestionNode(
    id: 'start',
    prompt: 'How will you use Stride?',
    helperText: 'Pick one option to continue.',
    options: const [
      AnswerOption(id: 'self', label: 'For myself'),
      AnswerOption(id: 'client_setup', label: 'Setting up for a client'),
    ],
    minSelections: 1,
    maxSelections: 1,
    nextNodeId: 'self.type',
  ),
  'self.type': QuestionNode(
    id: 'self.type',
    prompt: 'Which best describes you?',
    options: const [
      AnswerOption(id: 'independent', label: 'Independent'),
      AnswerOption(id: 'org_client', label: 'Client of an organization'),
    ],
    minSelections: 1,
    maxSelections: 1,
    nextNodeId: 'shared.profile',
  ),
  'shared.profile': QuestionNode(
    id: 'shared.profile',
    prompt: 'Select goals (you can choose several).',
    helperText: 'Minimum 1, maximum 3.',
    options: const [
      AnswerOption(id: 'mobility', label: 'Improve mobility'),
      AnswerOption(id: 'balance', label: 'Better balance'),
      AnswerOption(id: 'strength', label: 'Increase strength'),
      AnswerOption(id: 'endurance', label: 'Boost endurance'),
    ],
    minSelections: 1,
    maxSelections: 3,
    nextNodeId: 'summary',
  ),
  'summary': QuestionNode(
    id: 'summary',
    prompt: 'Almost Done! We just need your email address.',
    options: const [],
    textInputs: const [
      TextInputSpec(
        id: 'name',
        label: 'Full Name',
        placeholder: 'John Doe',
        errorMessage: 'Enter your full name',
      ),
      TextInputSpec(
        id: 'email',
        label: 'Email Address',
        placeholder: 'you@example.com',
        // Basic email pattern (validated case-insensitive at runtime)
        errorMessage: 'Enter a valid email',
      ),

    ],
    minSelections: 0,
    maxSelections: 0,
    terminal: true,
  ),
};
