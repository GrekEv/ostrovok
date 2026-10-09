import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/catalog.dart';
import '../theme.dart';
import '../widgets/mascot.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.state, super.key});
  final AppState state;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  final _countries = <String>{};
  final _priorities = <String>{};
  var _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _page == 0
            ? null
            : IconButton(
                onPressed: _previous,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        actions: [
          TextButton(
            onPressed: () => widget.state.completeOnboarding(
              countries: const [],
              priorities: const [],
              skipped: true,
            ),
            child: const Text('Пропустить'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PageView(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (value) => setState(() => _page = value),
        children: [
          _Welcome(onNext: _next),
          _Countries(
            selection: _countries,
            onChanged: () => setState(() {}),
            onNext: _next,
          ),
          _Priorities(
            selection: _priorities,
            onChanged: () => setState(() {}),
            onComplete: () => widget.state.completeOnboarding(
              countries: _countries,
              priorities: _priorities,
              skipped: false,
            ),
          ),
        ],
      ),
    );
  }

  void _next() => _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );

  void _previous() => _controller.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        children: [
          const Spacer(),
          const Mascot(size: 190),
          const SizedBox(height: 24),
          Text(
            'Я Островок',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const Text(
            'Помогу выбрать отель, хостел, тур или перелёт. '
            'Сначала расскажите, куда вас тянет.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 16),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onNext,
            child: const Text('Выбрать страны'),
          ),
        ],
      ),
    );
  }
}

class _Countries extends StatelessWidget {
  const _Countries({
    required this.selection,
    required this.onChanged,
    required this.onNext,
  });

  final Set<String> selection;
  final VoidCallback onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Mascot(size: 82, wink: true),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Куда хотели бы поехать?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final country in countries)
                    FilterChip(
                      label: Text('${country.emoji}  ${country.name}'),
                      selected: selection.contains(country.code),
                      onSelected: (selected) {
                        selected
                            ? selection.add(country.code)
                            : selection.remove(country.code);
                        onChanged();
                      },
                    ),
                ],
              ),
            ),
          ),
          FilledButton(
            onPressed: onNext,
            child: Text(selection.isEmpty ? 'Дальше без стран' : 'Дальше'),
          ),
        ],
      ),
    );
  }
}

class _Priorities extends StatelessWidget {
  const _Priorities({
    required this.selection,
    required this.onChanged,
    required this.onComplete,
  });

  final Set<String> selection;
  final VoidCallback onChanged;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Mascot(size: 82),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Что важно в путешествии?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: priorities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = priorities[index];
                final selected = selection.contains(item.id);
                return Material(
                  color: selected ? AppColors.leaf : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: TextStyle(
                        color: selected ? Colors.white70 : AppColors.muted,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check_circle, color: Colors.white)
                        : null,
                    onTap: () {
                      selected
                          ? selection.remove(item.id)
                          : selection.add(item.id);
                      onChanged();
                    },
                  ),
                );
              },
            ),
          ),
          FilledButton(
            onPressed: onComplete,
            child: Text(
              selection.isEmpty
                  ? 'К универсальным предложениям'
                  : 'К карточкам',
            ),
          ),
        ],
      ),
    );
  }
}
