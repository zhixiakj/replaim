import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'drafts/drafts_page.dart';
import 'inbox/inbox_page.dart';
import 'kb/kb_page.dart';
import 'learn/learn_page.dart';
import 'rules/rules_page.dart';
import 'settings/settings_page.dart';
import 'spaces/spaces_page.dart';

/// 主框架：左侧 NavigationRail + 右侧内容区（桌面布局）。
/// 内容区顶部是空间切换条：所有数据页面都按当前空间分区。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  static const _pages = [
    InboxPage(),
    DraftsPage(),
    RulesPage(),
    KbPage(),
    LearnPage(),
    SpacesPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            minWidth: 84,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.inbox_outlined),
                selectedIcon: Icon(Icons.inbox),
                label: Text('收件箱'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.edit_note_outlined),
                selectedIcon: Icon(Icons.edit_note),
                label: Text('草稿箱'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.rule_outlined),
                selectedIcon: Icon(Icons.rule),
                label: Text('规则库'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: Text('知识库'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school),
                label: Text('学习中心'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.workspaces_outlined),
                selectedIcon: Icon(Icons.workspaces),
                label: Text('空间'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('设置'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Column(
              children: [
                const _SpaceSwitcherBar(),
                const Divider(height: 1, thickness: 1),
                Expanded(child: _pages[_index]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 空间切换条：当前空间名 + 下拉切换 + 概要信息 + 快速新建。
class _SpaceSwitcherBar extends ConsumerWidget {
  const _SpaceSwitcherBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacesState = ref.watch(spacesProvider);
    final cur = ref.watch(currentSpaceProvider);
    final space = cur.space;
    final llmName =
        ref.watch(llmProfilesProvider).byId(space?.llmProfileId)?.name;

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (appFlavor == 'dev') ...[
            const _DevBadge(),
            const SizedBox(width: 10),
          ],
          const Icon(Icons.workspaces_outlined, size: 18),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            tooltip: '切换空间',
            position: PopupMenuPosition.under,
            initialValue: space?.id,
            enabled: spacesState.spaces.isNotEmpty,
            onSelected: (id) =>
                ref.read(spaceSelectionProvider.notifier).switchTo(id),
            itemBuilder: (_) => [
              for (final s in spacesState.spaces)
                PopupMenuItem(
                  value: s.id,
                  child: Row(
                    children: [
                      Icon(
                        s.id == space?.id
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: s.id == space?.id
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(s.name, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Text('${s.accounts.length} 账号',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  space?.name ??
                      (spacesState.loaded ? '未选择空间' : '加载中…'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
          if (space != null) ...[
            const SizedBox(width: 12),
            Text(
              '${space.receiveAccounts.length} 收 / ${space.sendAccounts.length} 发'
              '${llmName == null ? "" : " · $llmName"}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
          ],
          const Spacer(),
          IconButton(
            tooltip: '新建空间',
            icon: const Icon(Icons.add),
            onPressed: () => _createSpace(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _createSpace(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建空间'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '空间名称（如店铺 / 品牌名）',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final space = await ref.read(spacesProvider.notifier).create(name);
    await ref.read(spaceSelectionProvider.notifier).switchTo(space.id);
  }
}

/// dev 构建（--flavor dev）角标：提示当前 App 使用独立数据与密钥，防止与正式版混淆。
class _DevBadge extends StatelessWidget {
  const _DevBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade700,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'DEV',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
