import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/common/app_scaffold.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class _FaqItem {
  final String id;
  final String question;
  final String answer;
  final int order;

  const _FaqItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.order,
  });

  factory _FaqItem.fromMap(Map<String, dynamic> m) => _FaqItem(
        id: m['id']?.toString() ?? '',
        question: m['question']?.toString() ?? '',
        answer: m['answer']?.toString() ?? '',
        order: (m['order'] as num?)?.toInt() ?? 0,
      );
}

class _FaqCategory {
  final String id;
  final String name;
  final int order;
  final List<_FaqItem> items;

  const _FaqCategory({
    required this.id,
    required this.name,
    required this.order,
    required this.items,
  });

  factory _FaqCategory.fromMap(Map<String, dynamic> m) {
    final rawItems = m['items'];
    final items = rawItems is List
        ? rawItems
            .map((e) => _FaqItem.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList()
        : <_FaqItem>[];
    return _FaqCategory(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      order: (m['order'] as num?)?.toInt() ?? 0,
      items: items,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final _faqProvider = FutureProvider<List<_FaqCategory>>((ref) async {
  final raw = await ApiService.getFaq();
  return raw
      .map((e) => _FaqCategory.fromMap(e))
      .toList()
    ..sort((a, b) => a.order.compareTo(b.order));
});

// ── Screen ────────────────────────────────────────────────────────────────────

class FaqScreen extends ConsumerStatefulWidget {
  const FaqScreen({super.key});

  @override
  ConsumerState<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends ConsumerState<FaqScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  final Set<String> _expanded = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_FaqCategory> _filter(List<_FaqCategory> cats) {
    if (_query.isEmpty) return cats;
    final q = _query.toLowerCase();
    final result = <_FaqCategory>[];
    for (final cat in cats) {
      final matched = cat.items
          .where((i) =>
              i.question.toLowerCase().contains(q) ||
              i.answer.toLowerCase().contains(q))
          .toList();
      if (matched.isNotEmpty || cat.name.toLowerCase().contains(q)) {
        result.add(_FaqCategory(
          id: cat.id,
          name: cat.name,
          order: cat.order,
          items: matched.isEmpty ? cat.items : matched,
        ));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final faqAsync = ref.watch(_faqProvider);

    return MbongoPageScaffold(
      title: 'FAQ',
      child: Column(
        children: [
          // ── Barre de recherche ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              style: const TextStyle(color: AppColors.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rechercher une question…',
                hintStyle:
                    const TextStyle(color: AppColors.muted, fontSize: 13),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppColors.muted),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppColors.muted),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: palette.panelAlt,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppColors.border.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: palette.accent.withValues(alpha: 0.6)),
                ),
              ),
            ),
          ),

          // ── Contenu ───────────────────────────────────────────────────────
          Expanded(
            child: faqAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        color: AppColors.muted, size: 48),
                    const SizedBox(height: 12),
                    const Text('Impossible de charger la FAQ',
                        style:
                            TextStyle(color: AppColors.muted, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(_faqProvider),
                      child: Text('Réessayer',
                          style: TextStyle(color: palette.accent)),
                    ),
                  ],
                ),
              ),
              data: (cats) {
                final filtered = _filter(cats);
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            color: AppColors.muted, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _query.isNotEmpty
                              ? 'Aucun résultat pour "$_query"'
                              : 'Aucune question disponible',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: palette.accent,
                  onRefresh: () async => ref.invalidate(_faqProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, ci) {
                      final cat = filtered[ci];
                      final isExpanded = _expanded.contains(cat.id) ||
                          _query.isNotEmpty;
                      return _CategoryCard(
                        category: cat,
                        isExpanded: isExpanded,
                        palette: palette,
                        onToggle: () {
                          setState(() {
                            if (_expanded.contains(cat.id)) {
                              _expanded.remove(cat.id);
                            } else {
                              _expanded.add(cat.id);
                            }
                          });
                        },
                        query: _query,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category card (accordéon) ─────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final _FaqCategory category;
  final bool isExpanded;
  final MbongoThemePalette palette;
  final VoidCallback onToggle;
  final String query;

  const _CategoryCard({
    required this.category,
    required this.isExpanded,
    required this.palette,
    required this.onToggle,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.border.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.folder_open_rounded,
                        color: palette.accent, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.name,
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${category.items.length}',
                      style: TextStyle(
                        color: palette.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.muted, size: 20),
                  ),
                ],
              ),
            ),
          ),

          // ── Items ────────────────────────────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(
                    height: 1,
                    color: AppColors.border.withValues(alpha: 0.2)),
                ...category.items.asMap().entries.map((e) {
                  final isLast = e.key == category.items.length - 1;
                  return _FaqItemTile(
                    item: e.value,
                    palette: palette,
                    isLast: isLast,
                    query: query,
                  );
                }),
              ],
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

// ── Item tile ─────────────────────────────────────────────────────────────────

class _FaqItemTile extends StatefulWidget {
  final _FaqItem item;
  final MbongoThemePalette palette;
  final bool isLast;
  final String query;

  const _FaqItemTile({
    required this.item,
    required this.palette,
    required this.isLast,
    required this.query,
  });

  @override
  State<_FaqItemTile> createState() => _FaqItemTileState();
}

class _FaqItemTileState extends State<_FaqItemTile> {
  bool _open = false;

  TextSpan _highlight(String text, TextStyle base) {
    if (widget.query.isEmpty) return TextSpan(text: text, style: base);
    final q = widget.query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    while (true) {
      final idx = text.toLowerCase().indexOf(q, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start), style: base));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: base));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + q.length),
        style: base.copyWith(
          backgroundColor:
              widget.palette.accentStrong.withValues(alpha: 0.3),
          color: AppColors.text,
        ),
      ));
      start = idx + q.length;
    }
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.help_outline_rounded,
                    size: 16,
                    color: widget.palette.accentStrong,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: _highlight(
                      widget.item.question,
                      const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _open ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.muted, size: 18),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding:
                const EdgeInsets.fromLTRB(42, 0, 16, 12),
            child: RichText(
              text: _highlight(
                widget.item.answer,
                const TextStyle(
                  color: AppColors.textSoft,
                  fontSize: 13,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          crossFadeState:
              _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (!widget.isLast)
          Divider(
            height: 1,
            indent: 42,
            color: AppColors.border.withValues(alpha: 0.15),
          ),
      ],
    );
  }
}
