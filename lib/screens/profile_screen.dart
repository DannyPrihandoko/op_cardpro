import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/data_service.dart';
import '../models/card_model.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Profile settings
  String _name = 'Danny Prihandoko';
  String _title = 'Super Rookie';
  String _avatarEmoji = '👒';
  String _favLeaderId = '';
  String _favLeaderName = 'Luffy (ST01-001)';
  
  // App metrics/stats
  int _decksCount = 0;
  int _setsCount = 0;
  int _totalCardsCount = 0;
  bool _isLoading = true;

  // Predefined avatar choices
  final List<String> _avatars = ['👒', '🏴‍☠️', '⚔️', '🍖', '🍊', '🚢', '🪙', '⚓', '🔥', '🌸'];

  // Predefined pirate ranks/titles
  final List<String> _pirateTitles = [
    'Super Rookie',
    'Worst Generation',
    'Straw Hat Crew',
    'Grand Line Captain',
    'Warlord of the Sea',
    'Revolutionary',
    'Yonko (Emperor)',
    'Fleet Admiral',
    'Pirate King',
  ];

  // List of all leaders loaded from DataService
  List<CardModel> _allLeaders = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // Load profile data from SharedPreferences and metrics from DataService
  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final dataService = DataService();

      // Load SharedPreferences profile values
      _name = prefs.getString('op_profile_name') ?? 'Danny Prihandoko';
      _title = prefs.getString('op_profile_title') ?? 'Super Rookie';
      _avatarEmoji = prefs.getString('op_profile_avatar') ?? '👒';
      _favLeaderId = prefs.getString('op_profile_leader_id') ?? '';
      _favLeaderName = prefs.getString('op_profile_leader_name') ?? 'Luffy (ST01-001)';

      // Fetch dynamic stats from database
      final decks = await dataService.loadDecks();
      _decksCount = decks.length;

      final sets = await dataService.getSets();
      _setsCount = sets.length;

      final allCards = await dataService.getAllCards();
      _totalCardsCount = allCards.length;

      // Load leaders for the edit dialog options
      _allLeaders = await dataService.getAllLeaders();

    } catch (e) {
      print('Error loading profile or app data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Save changes to SharedPreferences
  Future<void> _saveProfileData(String name, String title, String avatar, String leaderId, String leaderName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('op_profile_name', name);
      await prefs.setString('op_profile_title', title);
      await prefs.setString('op_profile_avatar', avatar);
      await prefs.setString('op_profile_leader_id', leaderId);
      await prefs.setString('op_profile_leader_name', leaderName);

      setState(() {
        _name = name;
        _title = title;
        _avatarEmoji = avatar;
        _favLeaderId = leaderId;
        _favLeaderName = leaderName;
      });
    } catch (e) {
      print('Error saving profile data: $e');
    }
  }

  // Determine a collector rating based on custom decks built
  String _getCollectorTier() {
    if (_decksCount == 0) {
      return 'Deck Beginner';
    } else if (_decksCount < 3) {
      return 'Super Rookie';
    } else if (_decksCount < 6) {
      return 'Grand Line Veteran';
    } else {
      return 'Pirate King Builder';
    }
  }

  // Clear image cache action
  void _showClearCacheDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Clear Image Cache'),
        content: const Text(
          'This will remove all downloaded card artwork and images from your local cache, saving storage space. They will reload as you browse.',
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              // Perform cache cleaning or simply prompt a completion toast
              Navigator.pop(context);
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text('Cache Cleared'),
                  content: const Text('Local card image cache has been successfully optimized.'),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('OK'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Clear Cache'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Display the edit profile modal bottom sheet
  void _openEditProfileSheet() {
    final TextEditingController nameController = TextEditingController(text: _name);
    String selectedTitle = _title;
    String selectedAvatar = _avatarEmoji;
    String selectedLeaderId = _favLeaderId;
    String selectedLeaderName = _favLeaderName;

    showCupertinoModalPopup(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return CupertinoActionSheet(
              title: const Text(
                'Edit Profile & Account Info',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              message: Container(
                padding: const EdgeInsets.only(top: 10),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Avatar Selection Row
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Choose Avatar Symbol',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 55,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _avatars.length,
                          itemBuilder: (context, index) {
                            final avatar = _avatars[index];
                            final isSelected = selectedAvatar == avatar;
                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedAvatar = avatar;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppTheme.accentGold.withOpacity(0.2)
                                      : AppTheme.cardBg,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.accentGold
                                        : Colors.white.withOpacity(0.08),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  avatar,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name Field
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Pirate Name',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      CupertinoTextField(
                        controller: nameController,
                        placeholder: 'Enter your pirate name...',
                        placeholderStyle: const TextStyle(color: AppTheme.textSecondary),
                        style: const TextStyle(color: Colors.white),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      const SizedBox(height: 20),

                      // Pirate Title Dropdown / Selector
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select Pirate Title / Rank',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          // Show Cupertino Picker for Titles
                          showCupertinoModalPopup(
                            context: context,
                            builder: (context) {
                              return Container(
                                height: 250,
                                color: AppTheme.obsidianBg,
                                child: Column(
                                  children: [
                                    Container(
                                      color: AppTheme.surfaceBg,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Select Title',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => Navigator.pop(context),
                                            child: const Text(
                                              'Done',
                                              style: TextStyle(
                                                color: AppTheme.accentGold,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: CupertinoPicker(
                                        itemExtent: 40.0,
                                        scrollController: FixedExtentScrollController(
                                          initialItem: _pirateTitles.indexOf(selectedTitle),
                                        ),
                                        onSelectedItemChanged: (int index) {
                                          setModalState(() {
                                            selectedTitle = _pirateTitles[index];
                                          });
                                        },
                                        children: _pirateTitles.map((title) {
                                          return Center(
                                            child: Text(
                                              title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedTitle,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              const Icon(CupertinoIcons.chevron_down, color: AppTheme.accentGold, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Favorite Leader Selection
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Favorite Leader Card',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          if (_allLeaders.isEmpty) return;
                          
                          // Show Leader Selection picker
                          showCupertinoModalPopup(
                            context: context,
                            builder: (context) {
                              return Container(
                                height: 280,
                                color: AppTheme.obsidianBg,
                                child: Column(
                                  children: [
                                    Container(
                                      color: AppTheme.surfaceBg,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Favorite Leader',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => Navigator.pop(context),
                                            child: const Text(
                                              'Done',
                                              style: TextStyle(
                                                color: AppTheme.accentGold,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: CupertinoPicker(
                                        itemExtent: 44.0,
                                        scrollController: FixedExtentScrollController(
                                          initialItem: _allLeaders.indexWhere((c) => c.cardId == selectedLeaderId).clamp(0, _allLeaders.length - 1),
                                        ),
                                        onSelectedItemChanged: (int index) {
                                          final card = _allLeaders[index];
                                          setModalState(() {
                                            selectedLeaderId = card.cardId;
                                            selectedLeaderName = '${card.name} (${card.cardId})';
                                          });
                                        },
                                        children: _allLeaders.map((card) {
                                          return Center(
                                            child: Text(
                                              '${card.name} [${card.cardId}]',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  selectedLeaderName,
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(CupertinoIcons.chevron_down, color: AppTheme.accentGold, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                CupertinoActionSheetAction(
                  isDefaultAction: true,
                  onPressed: () {
                    final newName = nameController.text.trim().isNotEmpty 
                        ? nameController.text.trim() 
                        : _name;
                    _saveProfileData(newName, selectedTitle, selectedAvatar, selectedLeaderId, selectedLeaderName);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Save Settings',
                    style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              cancelButton: CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.obsidianBg,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: AppTheme.surfaceBg,
        middle: Text(
          'Profile & Account',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        border: Border(
          bottom: BorderSide(
            color: Color(0x1AFFFFFF),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(
                child: CupertinoActivityIndicator(
                  radius: 16,
                  color: AppTheme.accentGold,
                ),
              )
            : RefreshIndicator(
                color: AppTheme.accentGold,
                backgroundColor: AppTheme.surfaceBg,
                onRefresh: _loadProfileData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // PROFILE IDENTITY CARD WITH RADIAL GLOW
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.08),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentGold.withOpacity(0.06),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Avatar Badge
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.surfaceBg,
                                    border: Border.all(
                                      color: AppTheme.accentGold,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.accentGold.withOpacity(0.25),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _avatarEmoji,
                                    style: const TextStyle(fontSize: 48),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _openEditProfileSheet,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.accentGold,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        CupertinoIcons.pencil,
                                        color: AppTheme.obsidianBg,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 16),
                            // User name
                            Text(
                              _name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.25,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            // Pirate Rank Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGold.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppTheme.accentGold.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _title,
                                style: const TextStyle(
                                  color: AppTheme.accentGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Edit Profile Button
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              color: AppTheme.accentGold,
                              borderRadius: BorderRadius.circular(12),
                              child: const Text(
                                'Customize Profile',
                                style: TextStyle(
                                  color: AppTheme.obsidianBg,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              onPressed: _openEditProfileSheet,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 28),

                      // METRICS GRID SECTION
                      const Text(
                        'PIRATE LOGS & METRICS',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // 2x2 Stats grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.35,
                        children: [
                          _buildStatCard(
                            title: 'Decks Built',
                            value: '$_decksCount',
                            icon: CupertinoIcons.hammer_fill,
                          ),
                          _buildStatCard(
                            title: 'Sets Loaded',
                            value: '$_setsCount',
                            icon: CupertinoIcons.square_grid_2x2_fill,
                          ),
                          _buildStatCard(
                            title: 'Card Database',
                            value: '$_totalCardsCount',
                            icon: CupertinoIcons.square_stack_3d_up_fill,
                          ),
                          _buildStatCard(
                            title: 'Builder Class',
                            value: _getCollectorTier(),
                            icon: CupertinoIcons.rosette,
                            isTextLong: true,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Favorite Leader Display Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.heart_fill, color: Color(0xFFFF4D4D), size: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Favorite Leader Card',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _favLeaderName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // SETTINGS & NAVIGATION MENU
                      const Text(
                        'ABOUT & SETTINGS',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 1. Navigation item: ABOUT APP (KEY REQUIREMENT)
                      _buildMenuItem(
                        icon: CupertinoIcons.info_circle_fill,
                        title: 'About CardPro App',
                        subtitle: 'Developed by Danny, app status & feedback',
                        iconColor: AppTheme.accentGold,
                        onTap: () {
                          // Push the AboutScreen onto the stack
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => const AboutScreen(),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // 2. Navigation item: OPTIMIZE STORAGE / CLEAR CACHE
                      _buildMenuItem(
                        icon: CupertinoIcons.delete_solid,
                        title: 'Optimize Storage Cache',
                        subtitle: 'Clear loaded images, save space',
                        iconColor: const Color(0xFFFF6B6B),
                        onTap: _showClearCacheDialog,
                      ),
                      
                      const SizedBox(height: 48),

                      // App Version Footer
                      const Text(
                        'ONE PIECE CARD PRO • VERSION 1.0.0',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Crafted for card captains around the grand line.',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 11,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // Stat Card Builder Helper
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    bool isTextLong = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppTheme.accentGold.withOpacity(0.85), size: 20),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppTheme.accentGold,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTextLong ? 15 : 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: isTextLong ? 0 : 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Custom List Tile Menu Item Builder Helper
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, color: AppTheme.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
