import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/provider/auth_provider.dart';
import '../../../../core/utils/colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/config/api_config.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_form_fields.dart' as form_fields;
import '../widgets/section_card.dart';
import '../widgets/profile_sections.dart';
import '../widgets/photo_viewer_widget.dart';
import '../widgets/camera_capture_widget.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onChangePassword;

  const ProfilePage({super.key, this.onChangePassword});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ProfileProvider _profileProvider;

  @override
  void initState() {
    super.initState();
    _profileProvider = ProfileProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      _profileProvider.initializeWithData(
        authProvider.userData,
        authProvider.userProfile,
      );
    });
  }

  @override
  void dispose() {
    _profileProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isMobile = MediaQuery.of(context).size.width < 600;

    return ChangeNotifierProvider.value(
      value: _profileProvider,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(context),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _ProfileHeader(
                      authProvider: authProvider,
                      onChangePassword: widget.onChangePassword,
                      onShowPhotoOptions: _showPhotoOptions,
                    ),
                    const SizedBox(height: 24),
                    _BasicInformationSection(isMobile: isMobile),
                    const SizedBox(height: 20),
                    DemographicsSection(
                      isEditing: _profileProvider.isEditing,
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 20),
                    AddressSection(
                      isEditing: _profileProvider.isEditing,
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 20),
                    EmergencyContactSection(
                      isEditing: _profileProvider.isEditing,
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 20),
                    if (!isMobile)
                      _SecuritySection(onChangePassword: widget.onChangePassword),
                    const SizedBox(height: 20),
                    _AccountInformationSection(authProvider: authProvider),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Personal Information',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      elevation: 0,
    );
  }

  Future<void> _showPhotoOptions(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _openCamera(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _openGallery(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCamera(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraCaptureWidget(),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _openGallery(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image selected: ${image.name}'),
            backgroundColor: Colors.green,
          ),
        );
        // TODO: Upload image to server
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      AppLogger.error('Error opening gallery: $e', tag: 'ProfilePage');
    }
  }

}

class _ProfileHeader extends StatelessWidget {
  final AuthProvider authProvider;
  final VoidCallback? onChangePassword;
  final Function(BuildContext)? onShowPhotoOptions;

  const _ProfileHeader({
    required this.authProvider,
    required this.onChangePassword,
    this.onShowPhotoOptions,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final userData = authProvider.userData;
    final profileData = authProvider.userProfile;
    final fullName = authProvider.fullName ?? 'User';
    final initials = userData?['firstname']?[0] ?? 'U';

    String? photoUrl = profileData?['profile_photo_url'];
    if (photoUrl != null) {
      photoUrl = ApiConfig.buildMediaUrl(photoUrl);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Stack(
        children: [
          Center(
            child: _buildAvatarSection(photoUrl, initials, fullName, context),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Consumer<ProfileProvider>(
              builder: (context, provider, _) {
                return IconButton(
                  onPressed: () => provider.toggleEditing(),
                  icon: Icon(provider.isEditing ? Icons.close : Icons.edit),
                  color: AppColors.primaryBlue,
                  iconSize: 24,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(
    String? photoUrl,
    String initials,
    String fullName,
    BuildContext context,
  ) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Stack(
      children: [
        GestureDetector(
          onTap: photoUrl != null
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhotoViewerWidget(
                        photoUrl: photoUrl!,
                        userName: fullName,
                      ),
                      fullscreenDialog: true,
                    ),
                  );
                }
              : null,
          child: CircleAvatar(
            radius: isMobile ? 50 : 60,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    initials,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Consumer<ProfileProvider>(
            builder: (context, provider, _) {
              if (provider.isEditing) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => onShowPhotoOptions?.call(context),
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    iconSize: 20,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

class _BasicInformationSection extends StatelessWidget {
  final bool isMobile;

  const _BasicInformationSection({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        return SectionCard(
          title: 'Basic Information',
          icon: Icons.person_outline,
          iconColor: AppColors.primaryBlue,
          iconBgColor: AppColors.primaryBlue.withOpacity(0.1),
          child: Column(
            children: [
              if (isMobile) ...[
                form_fields.ProfileFormFields.buildEditableField(
                  label: 'Last Name',
                  controller: provider.lastnameController,
                  enabled: provider.isEditing,
                  context: context,
                ),
                const SizedBox(height: 16),
                form_fields.ProfileFormFields.buildEditableField(
                  label: 'First Name',
                  controller: provider.firstnameController,
                  enabled: provider.isEditing,
                  context: context,
                ),
                const SizedBox(height: 16),
                form_fields.ProfileFormFields.buildEditableField(
                  label: 'Middle Name',
                  controller: provider.middlenameController,
                  enabled: provider.isEditing,
                  context: context,
                ),
                const SizedBox(height: 16),
                form_fields.ProfileFormFields.buildEditableField(
                  label: 'Name Extension',
                  controller: provider.nameExtController,
                  enabled: provider.isEditing,
                  context: context,
                ),
                const SizedBox(height: 16),
                form_fields.ProfileFormFields.buildEditableField(
                  label: 'Email Address',
                  controller: provider.emailController,
                  enabled: provider.isEditing,
                  keyboardType: TextInputType.emailAddress,
                  context: context,
                ),
                const SizedBox(height: 16),
                form_fields.ProfileFormFields.buildEditableField(
                  label: 'Contact Number',
                  controller: provider.contactController,
                  enabled: provider.isEditing,
                  keyboardType: TextInputType.phone,
                  context: context,
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: form_fields.ProfileFormFields.buildEditableField(
                        label: 'Last Name',
                        controller: provider.lastnameController,
                        enabled: provider.isEditing,
                        context: context,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: form_fields.ProfileFormFields.buildEditableField(
                        label: 'First Name',
                        controller: provider.firstnameController,
                        enabled: provider.isEditing,
                        context: context,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: form_fields.ProfileFormFields.buildEditableField(
                        label: 'Middle Name',
                        controller: provider.middlenameController,
                        enabled: provider.isEditing,
                        context: context,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: form_fields.ProfileFormFields.buildEditableField(
                        label: 'Name Extension',
                        controller: provider.nameExtController,
                        enabled: provider.isEditing,
                        context: context,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: form_fields.ProfileFormFields.buildEditableField(
                        label: 'Email Address',
                        controller: provider.emailController,
                        enabled: provider.isEditing,
                        keyboardType: TextInputType.emailAddress,
                        context: context,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: form_fields.ProfileFormFields.buildEditableField(
                        label: 'Contact Number',
                        controller: provider.contactController,
                        enabled: provider.isEditing,
                        keyboardType: TextInputType.phone,
                        context: context,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SecuritySection extends StatelessWidget {
  final VoidCallback? onChangePassword;

  const _SecuritySection({required this.onChangePassword});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SectionCard(
      title: 'Security',
      icon: Icons.lock_outline,
      iconColor: Colors.red,
      iconBgColor: Colors.red.withOpacity(0.1),
      child: InkWell(
        onTap: onChangePassword,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Update your account password',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.grey[600] : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountInformationSection extends StatelessWidget {
  final AuthProvider authProvider;

  const _AccountInformationSection({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SectionCard(
      title: 'Account Information',
      icon: Icons.account_circle_outlined,
      iconColor: const Color(0xFF795548),
      iconBgColor: const Color(0xFFD7CCC8),
      child: Column(
        children: [
          form_fields.ProfileFormFields.buildReadOnlyField(
            label: 'Username',
            value: authProvider.username ?? 'N/A',
            context: context,
          ),
          const SizedBox(height: 16),
          form_fields.ProfileFormFields.buildReadOnlyField(
            label: 'Role',
            value: authProvider.role ?? 'N/A',
            context: context,
          ),
          const SizedBox(height: 16),
          form_fields.ProfileFormFields.buildReadOnlyField(
            label: 'Deployment',
            value: authProvider.deployment ?? 'N/A',
            context: context,
          ),
          const SizedBox(height: 16),
          form_fields.ProfileFormFields.buildReadOnlyField(
            label: 'Account Status',
            value: authProvider.isActive ? 'Active' : 'Inactive',
            valueColor: authProvider.isActive ? Colors.green : Colors.red,
            context: context,
          ),
        ],
      ),
    );
  }
}
