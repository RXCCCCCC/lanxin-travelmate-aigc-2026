import 'package:flutter/material.dart';

import '../../../shared/widgets/glass_box.dart';
import '../data/chat_history_service.dart';

class TripChatHistorySheet extends StatelessWidget {
  const TripChatHistorySheet({
    super.key,
    required this.groups,
    required this.currentSessionId,
    required this.onNewSession,
    required this.onSelectSession,
    required this.onDeleteSession,
  });

  final List<TripConversationGroup> groups;
  final String currentSessionId;
  final VoidCallback onNewSession;
  final ValueChanged<ChatSessionEntry> onSelectSession;
  final ValueChanged<ChatSessionEntry> onDeleteSession;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 0, 14, 14 + bottomInset),
        child: GlassBox(
          borderRadius: BorderRadius.circular(28),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          opacity: 0.28,
          blur: 28,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.72,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7EA7DD).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '聊天历史',
                        style: TextStyle(
                          color: Color(0xFF06224E),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _SheetActionButton(
                      icon: Icons.add_rounded,
                      label: '新建对话',
                      onTap: onNewSession,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '按当前行程自动归类，像聊天列表一样继续上次对话。',
                  style: TextStyle(
                    color: Color(0xFF4E6F9B),
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: groups.isEmpty
                      ? const _EmptyHistory()
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: groups.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, groupIndex) {
                            final group = groups[groupIndex];
                            return _HistoryGroup(
                              group: group,
                              currentSessionId: currentSessionId,
                              onSelectSession: onSelectSession,
                              onDeleteSession: onDeleteSession,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryGroup extends StatelessWidget {
  const _HistoryGroup({
    required this.group,
    required this.currentSessionId,
    required this.onSelectSession,
    required this.onDeleteSession,
  });

  final TripConversationGroup group;
  final String currentSessionId;
  final ValueChanged<ChatSessionEntry> onSelectSession;
  final ValueChanged<ChatSessionEntry> onDeleteSession;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.map_rounded, size: 15, color: Color(0xFF215ECA)),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                group.tripTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF173E78),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...group.sessions.map(
          (session) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _SessionTile(
              session: session,
              selected: session.sessionId == currentSessionId,
              onTap: () => onSelectSession(session),
              onDeleteSession: () => onDeleteSession(session),
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.selected,
    required this.onTap,
    required this.onDeleteSession,
  });

  final ChatSessionEntry session;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDeleteSession;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF4C8DFF).withOpacity(0.22)
                : Colors.white.withOpacity(0.20),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF2D72E8).withOpacity(0.55)
                  : Colors.white.withOpacity(0.42),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? const Color(0xFF215ECA)
                      : Colors.white.withOpacity(0.42),
                ),
                child: Icon(
                  selected
                      ? Icons.chat_bubble_rounded
                      : Icons.chat_bubble_outline_rounded,
                  size: 17,
                  color: selected ? Colors.white : const Color(0xFF215ECA),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF06224E),
                        fontWeight: FontWeight.w900,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      session.lastMessage.isEmpty
                          ? '还没有开始聊天'
                          : session.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF59769B),
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onTap,
                tooltip: '载入到首页',
                icon: const Icon(
                  Icons.login_rounded,
                  color: Color(0xFF215ECA),
                  size: 18,
                ),
              ),
              IconButton(
                onPressed: onDeleteSession,
                tooltip: '删除对话',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFF8BA0BC),
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF215ECA),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF215ECA).withOpacity(0.22),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.45)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_rounded, color: Color(0xFF215ECA), size: 28),
          SizedBox(height: 8),
          Text(
            '还没有历史会话',
            style: TextStyle(
              color: Color(0xFF06224E),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '新建对话后，蓝小心会按行程帮你归档。',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF59769B), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
