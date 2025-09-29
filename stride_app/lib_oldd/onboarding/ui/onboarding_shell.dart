import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../flow/onboarding_controller.dart';
import '../models/nodes.dart';

class OnboardingShell extends StatelessWidget {
  const OnboardingShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => OnboardingController(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatelessWidget {
  const _OnboardingView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnboardingController>();
    final node = controller.currentNode;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: controller.canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back, size: 32),
                onPressed: controller.goBack,
                tooltip: 'Back',
              )
            : null,
        title: Text(
          'Setup',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) =>
            SlideTransition(position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(anim), child: child),
        child: _QuestionNodeView(key: ValueKey(node.id), node: node),
      ),
    );
  }
}

class _QuestionNodeView extends StatelessWidget {
  final QuestionNode node;
  const _QuestionNodeView({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnboardingController>();
    final theme = Theme.of(context);

    return LayoutBuilder(builder: (context, constraints) {
      final maxWidth = constraints.maxWidth < 640 ? constraints.maxWidth : 640.0;
      final single = node.isSingleSelect;
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(node.prompt, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                if (node.helperText != null) ...[
                  const SizedBox(height: 8),
                  Text(node.helperText!, style: theme.textTheme.bodyLarge),
                ],
                const SizedBox(height: 24),
                ...node.options.map((o) => Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                  child: _AnswerTile(option: o, node: node, single: single),
                )),
                if (node.textInputs.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  ...node.textInputs.map((spec) => _TextInputField(spec: spec, key: ValueKey(spec.id))),
                ],
                const SizedBox(height: 32),
                // const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: controller.canContinue()
                        ? () {
                            if (node.terminal) {
                              Navigator.of(context).pushReplacementNamed('/home');
                            } else {
                              controller.continueFlow();
                            }
                          }
                        : null,
                    child: Text(node.terminal ? 'Finish' : 'Continue'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _AnswerTile extends StatelessWidget {
  final AnswerOption option;
  final QuestionNode node;
  final bool single;
  const _AnswerTile({required this.option, required this.node, required this.single});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnboardingController>();
    final selected = controller.isSelected(option.id);
    final icon = single
        ? (selected ? Icons.radio_button_on : Icons.radio_button_off)
        : (selected ? Icons.check_box : Icons.check_box_outline_blank);
    return ListTile(
      onTap: () => controller.toggle(option.id),
      leading: Icon(icon, size: 30, color:  selected ? Theme.of(context).colorScheme.outline : Theme.of(context).colorScheme.outlineVariant),
      title: Text(option.label, style: Theme.of(context).textTheme.bodyLarge!.copyWith(
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      )),
      subtitle: option.description != null ? Text(option.description!) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular( single ? 180 : 4 ),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 2),
      ),
      tileColor: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      // selected: selected,

    );
  }
}

class _TextInputField extends StatefulWidget {
  final TextInputSpec spec;
  const _TextInputField({super.key, required this.spec});

  @override
  State<_TextInputField> createState() => _TextInputFieldState();
}

class _TextInputFieldState extends State<_TextInputField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OnboardingController>();
    final nodeId = controller.currentNode.id;
    final value = controller.textValues[nodeId]?[widget.spec.id];
    if (value != null && value != _controller.text) {
      _controller.text = value;
    }
    final valid = widget.spec.validate(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: _controller,
        keyboardType: widget.spec.id.contains('email') ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: widget.spec.label,
            hintText: widget.spec.placeholder,
          errorText: valid ? null : (widget.spec.errorMessage ?? 'Invalid'),
          border: const OutlineInputBorder(),
        ),
        onChanged: (v) => controller.updateTextValue(widget.spec.id, v),
      ),
    );
  }
}
