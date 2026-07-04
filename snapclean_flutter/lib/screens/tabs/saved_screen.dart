import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/snap_item.dart';
import '../../state/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/snap_widgets.dart';
import '../snap_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  final VoidCallback onImport;
  const SavedScreen({required this.onImport, super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  static const _imageImportChannel = MethodChannel('snapclean/image_import');
  String? selectedFolderId;
  List<SavedFolder> folders = const [];
  bool creatingFolder = false;
  bool pickingImages = false;
  String query = '';
  final folderName = TextEditingController();

  @override
  void dispose() {
    folderName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    if (selectedFolderId != null &&
        !folders.any((folder) => folder.id == selectedFolderId)) {
      selectedFolderId = null;
    }
    final selectedFolder = _selectedFolder(folders);
    final baseItems = selectedFolder == null
        ? controller.keptSnaps
        : _snapsInFolder(controller, selectedFolder.id);
    final items = _search(baseItems);
    final availableForSelected = selectedFolder == null
        ? const <SnapItem>[]
        : controller.keptSnaps
            .where((snap) => !selectedFolder.snapIds.contains(snap.id))
            .toList();
    return AppPage(
      eyebrow: 'Archive',
      title: 'Saved',
      scrollable: !creatingFolder && !pickingImages,
      child: SizedBox(
        height: creatingFolder || pickingImages
            ? MediaQuery.sizeOf(context).height - 178
            : null,
        child: LoadingOverlay(
          visible: pickingImages,
          title: 'Importing images',
          subtitle: 'Preparing archive previews from the emulator.',
          child: Stack(children: [
            IgnorePointer(
              ignoring: creatingFolder || pickingImages,
              child: Opacity(
                opacity: creatingFolder ? .24 : 1,
                child: Column(
                  children: [
                    AppSearchBar(
                        hint: 'Search archive',
                        onChanged: (value) => setState(() => query = value)),
                    const InsightCard(
                      icon: Icons.verified_user_rounded,
                      title: 'Only intentional archives live here',
                      subtitle:
                          'Archived screenshots have no countdown and stay separate from cleanup timers.',
                      color: AppColors.mint,
                    ),
                    SectionHeader(
                      title: 'Folders',
                      action: 'Create Folder',
                      onAction: _startCreateFolder,
                    ),
                    SavedFolderTabs(
                      folders: folders,
                      selectedFolderId: selectedFolderId,
                      countForFolder: (folder) =>
                          _snapsInFolder(controller, folder.id).length,
                      onAll: () => setState(() => selectedFolderId = null),
                      onFolder: (folder) =>
                          setState(() => selectedFolderId = folder.id),
                      onDelete: _confirmDeleteFolderFromSaved,
                    ),
                    SectionHeader(
                      title: selectedFolder?.name ?? 'Archive',
                      action: selectedFolder == null
                          ? '${items.length} saved'
                          : 'Manage',
                      onAction: selectedFolder == null
                          ? null
                          : () => _manageFolder(context, selectedFolder),
                    ),
                    if (items.isEmpty)
                      EmptyStateCard(
                        icon: query.trim().isEmpty
                            ? Icons.bookmark_rounded
                            : Icons.search_off_rounded,
                        title: query.trim().isEmpty
                            ? 'Archive is empty'
                            : 'No results found',
                        subtitle: query.trim().isEmpty
                            ? (selectedFolder == null
                                ? 'Save receipts, QR codes, confirmations, and screenshots you want to keep.'
                                : 'Tap Manage to add archived screenshots to this folder.')
                            : 'Try searching by screenshot name, folder, or note.',
                        actionLabel: selectedFolder == null
                            ? 'Import photos'
                            : availableForSelected.isEmpty
                                ? 'Import photos'
                                : 'Add screenshot',
                        actionIcon: selectedFolder == null ||
                                availableForSelected.isEmpty
                            ? Icons.add_photo_alternate_rounded
                            : Icons.add_rounded,
                        onAction: selectedFolder == null ||
                                availableForSelected.isEmpty
                            ? _pickArchiveImages
                            : () => _chooseScreenshot(context, selectedFolder),
                      )
                    else
                      for (final item in items)
                        SnapItemCard(
                          item: item,
                          actions: Row(
                            children: [
                              Expanded(
                                child: SecondaryButton(
                                  label: 'Delete',
                                  icon: Icons.delete_outline_rounded,
                                  onTap: () =>
                                      _confirmDeleteSaved(context, item.id),
                                ),
                              ),
                              if (selectedFolder != null) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SecondaryButton(
                                    label: 'Remove',
                                    icon: Icons.folder_delete_rounded,
                                    onTap: () => _removeSnapFromFolder(
                                        folderId: selectedFolder.id,
                                        snapId: item.id),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SnapDetailScreen(item: item),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            if (creatingFolder) ...[
              Positioned.fill(
                child: Container(color: const Color(0x990F172A)),
              ),
              Center(
                child: _CreateFolderCard(
                  controller: folderName,
                  onCancel: _cancelCreateFolder,
                  onCreate: _submitFolder,
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  List<SnapItem> _search(List<SnapItem> items) {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return items;
    return items
        .where((item) =>
            item.title.toLowerCase().contains(term) ||
            item.note.toLowerCase().contains(term))
        .toList(growable: false);
  }

  SavedFolder? _selectedFolder(List<SavedFolder> folders) {
    for (final folder in folders) {
      if (folder.id == selectedFolderId) return folder;
    }
    return null;
  }

  List<SnapItem> _snapsInFolder(AppController controller, String folderId) {
    SavedFolder? folder;
    for (final item in folders) {
      if (item.id == folderId) {
        folder = item;
        break;
      }
    }
    if (folder == null) return const [];
    final snapIds = folder.snapIds;
    return controller.keptSnaps
        .where((snap) => snapIds.contains(snap.id))
        .toList(growable: false);
  }

  void _startCreateFolder() {
    setState(() => creatingFolder = true);
  }

  void _cancelCreateFolder() {
    folderName.clear();
    setState(() => creatingFolder = false);
  }

  void _submitFolder() {
    final trimmed = folderName.text.trim();
    final folder = SavedFolder(
      id: 'folder-${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed.isEmpty ? 'New folder' : trimmed,
      createdAt: DateTime.now(),
    );
    folderName.clear();
    setState(() {
      folders = [folder, ...folders];
      selectedFolderId = folder.id;
      creatingFolder = false;
    });
  }

  Future<void> _pickArchiveImages() async {
    if (pickingImages) return;
    setState(() => pickingImages = true);
    try {
      final images =
          await _imageImportChannel.invokeListMethod<String>('pickImages');
      if (!mounted) return;
      if (images == null || images.isEmpty) {
        setState(() => pickingImages = false);
        return;
      }
      SnapCleanScope.of(context).saveArchivedImages(images);
      setState(() {
        selectedFolderId = null;
        pickingImages = false;
      });
      if (!mounted) return;
      showSuccessSheet(
        context,
        title: 'Saved to Archive',
        message:
            '${images.length} ${images.length == 1 ? 'screenshot' : 'screenshots'} will not be auto-deleted.',
        primaryLabel: 'View Archive',
        primaryIcon: Icons.bookmark_rounded,
        onPrimary: () => setState(() => selectedFolderId = null),
        secondaryLabel: 'Create folder',
        secondaryIcon: Icons.create_new_folder_rounded,
        onSecondary: _startCreateFolder,
      );
    } catch (_) {
      if (!mounted) return;
      SnapCleanScope.of(context).saveSampleArchive();
      setState(() {
        selectedFolderId = null;
        pickingImages = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'The emulator picker is unavailable here, so sample archive shots were added.')),
      );
    }
  }

  void _confirmDeleteFolderFromSaved(SavedFolder folder) {
    showConfirmSheet(context,
            title: 'Delete folder?',
            message:
                '"${folder.name}" will be removed. Archived screenshots stay in Archive.',
            confirmLabel: 'Delete',
            icon: Icons.folder_delete_rounded,
            danger: true)
        .then((confirmed) {
      if (!confirmed || !mounted) return;
      setState(() {
        folders = folders
            .where((item) => item.id != folder.id)
            .toList(growable: false);
        if (selectedFolderId == folder.id) selectedFolderId = null;
      });
    });
  }

  void _manageFolder(BuildContext context, SavedFolder folder) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyStateCard(
                icon: Icons.folder_rounded,
                title: folder.name,
                subtitle:
                    '${_snapsInFolder(SnapCleanScope.of(context), folder.id).length} archived screenshots'),
            PrimaryButton(
                label: 'Add screenshots',
                icon: Icons.add_photo_alternate_rounded,
                onTap: () {
                  Navigator.pop(context);
                  _chooseScreenshot(context, folder);
                }),
            const SizedBox(height: 12),
            SecondaryButton(
                label: 'Rename folder',
                icon: Icons.edit_rounded,
                onTap: () {
                  Navigator.pop(context);
                  _renameLocalFolder(folder);
                }),
            const SizedBox(height: 12),
            SecondaryButton(
                label: 'Delete folder',
                icon: Icons.delete_outline_rounded,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteFolderFromSaved(folder);
                }),
          ],
        ),
      ),
    );
  }

  void _renameLocalFolder(SavedFolder folder) {
    final controller = TextEditingController(text: folder.name);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppField(label: 'Folder name', value: '', controller: controller),
            const SizedBox(height: 14),
            PrimaryButton(
                label: 'Save folder name',
                icon: Icons.check_rounded,
                onTap: () {
                  final next = controller.text.trim();
                  if (next.isNotEmpty) {
                    setState(() {
                      folders = [
                        for (final item in folders)
                          item.id == folder.id
                              ? item.copyWith(name: next)
                              : item
                      ];
                    });
                  }
                  Navigator.pop(context);
                }),
          ],
        ),
      ),
    ).then((_) => controller.dispose());
  }

  void _chooseScreenshot(BuildContext context, SavedFolder folder) {
    final controller = SnapCleanScope.of(context);
    final available = controller.keptSnaps
        .where((snap) => !folder.snapIds.contains(snap.id))
        .toList();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SectionHeader(title: 'Add to ${folder.name}', action: ''),
            for (final item in available)
              ListTile(
                leading: Icon(item.type == MockType.travel
                    ? Icons.qr_code_rounded
                    : Icons.image_rounded),
                title: Text(item.title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(item.note),
                trailing: const Icon(Icons.add_circle_outline_rounded,
                    color: AppColors.brand),
                onTap: () {
                  _addSnapToFolder(folderId: folder.id, snapId: item.id);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteSaved(BuildContext context, String id) {
    showConfirmSheet(context,
            title: 'Delete screenshot?',
            message:
                'This moves it to Recently Deleted. You can review it later.',
            confirmLabel: 'Delete',
            icon: Icons.delete_outline_rounded,
            danger: true)
        .then((confirmed) {
      if (!confirmed || !mounted) return;
      SnapCleanScope.of(context).deleteSnap(id);
      setState(() => _removeSnapFromFolders(id));
    });
  }

  void _addSnapToFolder({required String folderId, required String snapId}) {
    setState(() {
      folders = [
        for (final folder in folders)
          if (folder.id == folderId)
            folder.snapIds.contains(snapId)
                ? folder
                : folder.copyWith(snapIds: [...folder.snapIds, snapId])
          else
            folder
      ];
    });
  }

  void _removeSnapFromFolder(
      {required String folderId, required String snapId}) {
    setState(() {
      folders = [
        for (final folder in folders)
          folder.id == folderId
              ? folder.copyWith(
                  snapIds: folder.snapIds.where((id) => id != snapId).toList())
              : folder
      ];
    });
  }

  void _removeSnapFromFolders(String snapId) {
    folders = [
      for (final folder in folders)
        folder.copyWith(
            snapIds: folder.snapIds.where((id) => id != snapId).toList())
    ];
  }
}

class SavedFolderScreen extends StatelessWidget {
  final String folderId;
  const SavedFolderScreen({required this.folderId, super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    final folder = _folder(controller);
    if (folder == null) {
      return Scaffold(
        body: AppPage(
          eyebrow: 'Folder',
          title: 'Folder deleted',
          leading: RoundIcon(
              icon: Icons.chevron_left_rounded,
              onTap: () => Navigator.pop(context)),
          child: const InsightCard(
            icon: Icons.folder_off_rounded,
            title: 'This folder is no longer available',
            subtitle: 'Return to Saved to continue organizing screenshots.',
            color: AppColors.amber,
          ),
        ),
      );
    }

    final items = controller.snapsInFolder(folderId);
    final available = controller.keptSnaps
        .where((snap) => !folder.snapIds.contains(snap.id))
        .toList();
    return Scaffold(
      body: AppPage(
        eyebrow: 'Saved folder',
        title: folder.name,
        leading: RoundIcon(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.pop(context)),
        child: Column(
          children: [
            AppCard(
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.folder_rounded,
                        color: AppColors.brandDark, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(folder.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 19, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 4),
                        Text(
                            items.length == 1
                                ? '1 saved screenshot'
                                : '${items.length} saved screenshots',
                            style: AppText.label),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Rename',
                    icon: Icons.edit_rounded,
                    onTap: () => _renameFolder(context, folder),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryButton(
                    label: 'Delete',
                    icon: Icons.delete_outline_rounded,
                    onTap: () => _confirmDeleteFolder(context, folder),
                  ),
                ),
              ],
            ),
            SectionHeader(
              title: 'Screenshots',
              action: available.isEmpty ? 'All added' : 'Add',
              onAction:
                  available.isEmpty ? null : () => _chooseScreenshot(context),
            ),
            if (items.isEmpty)
              InsightCard(
                icon: Icons.add_photo_alternate_rounded,
                title: 'This folder is empty',
                subtitle: available.isEmpty
                    ? 'Import archived shots first, then add them here.'
                    : 'Tap Add to organize saved screenshots into this folder.',
                color: AppColors.brand,
              )
            else
              for (final item in items)
                SnapItemCard(
                  item: item,
                  actions: Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          label: 'Remove from folder',
                          icon: Icons.folder_delete_rounded,
                          onTap: () => controller.removeSnapFromFolder(
                              folderId: folderId, snapId: item.id),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SnapDetailScreen(item: item),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  SavedFolder? _folder(AppController controller) {
    for (final folder in controller.savedFolders) {
      if (folder.id == folderId) return folder;
    }
    return null;
  }

  void _chooseScreenshot(BuildContext context) {
    final controller = SnapCleanScope.of(context);
    final folder = _folder(controller);
    if (folder == null) return;
    final available = controller.keptSnaps
        .where((snap) => !folder.snapIds.contains(snap.id))
        .toList();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SectionHeader(title: 'Add screenshot', action: ''),
            for (final item in available)
              ListTile(
                leading: Icon(item.type == MockType.travel
                    ? Icons.qr_code_rounded
                    : Icons.image_rounded),
                title: Text(item.title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text(item.note),
                trailing: const Icon(Icons.add_circle_outline_rounded,
                    color: AppColors.brand),
                onTap: () {
                  controller.addSnapToFolder(
                      folderId: folderId, snapId: item.id);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _renameFolder(BuildContext context, SavedFolder folder) {
    final name = TextEditingController(text: folder.name);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename folder'),
        content: TextField(
          controller: name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Folder name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              SnapCleanScope.of(context)
                  .renameSavedFolder(folder.id, name.text);
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) => name.dispose());
  }

  void _confirmDeleteFolder(BuildContext context, SavedFolder folder) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text(
            '"${folder.name}" will be removed. Saved screenshots stay in Saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              SnapCleanScope.of(context).deleteSavedFolder(folder.id);
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _CreateFolderCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onCancel;
  final VoidCallback onCreate;
  const _CreateFolderCard(
      {required this.controller,
      required this.onCancel,
      required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x330F172A),
                  blurRadius: 34,
                  offset: Offset(0, 18))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.create_new_folder_rounded,
                      color: AppColors.brandDark),
                  SizedBox(width: 9),
                  Text('New folder', style: AppText.value),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Folder name',
                  filled: true,
                  fillColor: AppColors.soft,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: AppColors.brand, width: 2),
                  ),
                ),
                onSubmitted: (_) => onCreate(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Cancel',
                      icon: Icons.close_rounded,
                      onTap: onCancel,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Create',
                      icon: Icons.check_rounded,
                      onTap: onCreate,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SavedFolderTabs extends StatelessWidget {
  final List<SavedFolder> folders;
  final String? selectedFolderId;
  final int Function(SavedFolder folder) countForFolder;
  final VoidCallback onAll;
  final ValueChanged<SavedFolder> onFolder;
  final ValueChanged<SavedFolder> onDelete;
  const SavedFolderTabs(
      {required this.folders,
      required this.selectedFolderId,
      required this.countForFolder,
      required this.onAll,
      required this.onFolder,
      required this.onDelete,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SavedFolderTab(
              label: 'All',
              count: null,
              active: selectedFolderId == null,
              icon: Icons.bookmark_rounded,
              onTap: onAll,
              onDelete: null,
            ),
            for (final folder in folders) ...[
              const SizedBox(width: 8),
              SavedFolderTab(
                label: folder.name,
                count: countForFolder(folder),
                active: selectedFolderId == folder.id,
                icon: Icons.folder_rounded,
                onTap: () => onFolder(folder),
                onDelete: selectedFolderId == folder.id
                    ? () => onDelete(folder)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SavedFolderTab extends StatelessWidget {
  final String label;
  final int? count;
  final bool active;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  const SavedFolderTab(
      {required this.label,
      required this.count,
      required this.active,
      required this.icon,
      required this.onTap,
      required this.onDelete,
      super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 42, maxWidth: 170),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.brand : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: active ? AppColors.brand : const Color(0xFFE2E8F0)),
          boxShadow: active
              ? const [
                  BoxShadow(
                      color: Color(0x1A0891B2),
                      blurRadius: 14,
                      offset: Offset(0, 8))
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 17, color: active ? Colors.white : AppColors.brandDark),
            const SizedBox(width: 7),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: active ? Colors.white : AppColors.ink)),
            ),
            if (count != null) ...[
              const SizedBox(width: 7),
              Text('$count',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color:
                          active ? const Color(0xCCFFFFFF) : AppColors.subtle)),
            ],
            if (onDelete != null) ...[
              const SizedBox(width: 7),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close_rounded,
                    size: 16, color: active ? Colors.white : AppColors.subtle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class SavedFolderCard extends StatelessWidget {
  final SavedFolder folder;
  final int count;
  final VoidCallback onTap;
  const SavedFolderCard(
      {required this.folder,
      required this.count,
      required this.onTap,
      super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
          boxShadow: const [
            BoxShadow(
                color: Color(0x080F172A), blurRadius: 14, offset: Offset(0, 8))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  const Icon(Icons.folder_rounded, color: AppColors.brandDark),
            ),
            const Spacer(),
            Text(folder.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.ink)),
            const SizedBox(height: 4),
            Text(count == 1 ? '1 screenshot' : '$count screenshots',
                style: AppText.label),
          ],
        ),
      ),
    );
  }
}
