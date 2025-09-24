import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../presentation/theme/app_theme.dart';
import '../../../presentation/controllers/theme_controller.dart';
import '../../../presentation/widgets/theme_toggle_widget.dart';
import '../../widgets/bottom_navigation_dock.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ThemeController themeController = Get.find<ThemeController>();

  bool notificationsEnabled = true;
  bool emailNotifications = true;
  bool pushNotifications = true;
  bool soundEnabled = true;
  bool autoDownload = false;
  String selectedLanguage = 'Español';
  String selectedQuality = 'Alta';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // quita el botón de atrás
        title: Text(
          'Configuración',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // configuración de apariencia
              _buildAppearanceSection(),
              const SizedBox(height: 24),
              // configuración de notificaciones
              _buildNotificationsSection(),
              const SizedBox(height: 24),
              // configuración de descarga y reproducción
              _buildDownloadSection(),
              const SizedBox(height: 24),
              // configuración de idioma y región
              _buildLanguageSection(),
              const SizedBox(height: 24),
              // configuración de cuenta
              _buildAccountSection(),
              const SizedBox(height: 24),
              // información de la aplicación
              _buildAppInfoSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavigationDock(currentIndex: 4),
    );
  }

  Widget _buildAppearanceSection() {
    return _buildSettingsCard(
      title: 'Apariencia',
      icon: Icons.palette,
      children: [
        _buildSettingsRow(
          title: 'Tema',
          subtitle: 'Cambiar entre tema claro y oscuro',
          trailing: const ThemeToggleWidget(),
        ),
        const Divider(height: 24),
        _buildSettingsRow(
          title: 'Tamaño de Fuente',
          subtitle: 'Ajustar el tamaño del texto',
          trailing: DropdownButton<String>(
            value: 'Medio',
            underline: const SizedBox(),
            items: ['Pequeño', 'Medio', 'Grande'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              // TODO: implementas cambio de tamaño de fuente
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return _buildSettingsCard(
      title: 'Notificaciones',
      icon: Icons.notifications,
      children: [
        _buildSwitchRow(
          title: 'Habilitar Notificaciones',
          subtitle: 'Recibir notificaciones de la aplicación',
          value: notificationsEnabled,
          onChanged: (value) {
            setState(() {
              notificationsEnabled = value;
            });
          },
        ),
        const Divider(height: 24),
        _buildSwitchRow(
          title: 'Notificaciones por Email',
          subtitle: 'Recibir notificaciones en tu correo',
          value: emailNotifications,
          onChanged: (value) {
            setState(() {
              emailNotifications = value;
            });
          },
        ),
        const Divider(height: 24),
        _buildSwitchRow(
          title: 'Notificaciones Push',
          subtitle: 'Notificaciones instantáneas en el dispositivo',
          value: pushNotifications,
          onChanged: (value) {
            setState(() {
              pushNotifications = value;
            });
          },
        ),
        const Divider(height: 24),
        _buildSwitchRow(
          title: 'Sonido',
          subtitle: 'Reproducir sonido con las notificaciones',
          value: soundEnabled,
          onChanged: (value) {
            setState(() {
              soundEnabled = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDownloadSection() {
    return _buildSettingsCard(
      title: 'Descarga y Reproducción',
      icon: Icons.download,
      children: [
        _buildSwitchRow(
          title: 'Descarga Automática',
          subtitle: 'Descargar contenido automáticamente',
          value: autoDownload,
          onChanged: (value) {
            setState(() {
              autoDownload = value;
            });
          },
        ),
        const Divider(height: 24),
        _buildSettingsRow(
          title: 'Calidad de Video',
          subtitle: 'Calidad por defecto para videos',
          trailing: DropdownButton<String>(
            value: selectedQuality,
            underline: const SizedBox(),
            items: ['Baja', 'Media', 'Alta', 'Auto'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedQuality = newValue!;
              });
            },
          ),
        ),
        const Divider(height: 24),
        _buildSettingsRow(
          title: 'Gestionar Descargas',
          subtitle: 'Ver y eliminar contenido descargado',
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          onTap: () {
            Get.snackbar(
              'Gestionar Descargas',
              'Funcionalidad próximamente disponible',
              backgroundColor: AppTheme.goldAccent,
              colorText: AppTheme.premiumBlack,
            );
          },
        ),
      ],
    );
  }

  Widget _buildLanguageSection() {
    return _buildSettingsCard(
      title: 'Idioma y Región',
      icon: Icons.language,
      children: [
        _buildSettingsRow(
          title: 'Idioma',
          subtitle: 'Idioma de la aplicación',
          trailing: DropdownButton<String>(
            value: selectedLanguage,
            underline: const SizedBox(),
            items: ['Español', 'English', 'Français'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedLanguage = newValue!;
              });
            },
          ),
        ),
        const Divider(height: 24),
        _buildSettingsRow(
          title: 'Región',
          subtitle: 'México',
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          onTap: () {
            Get.snackbar(
              'Configuración de Región',
              'Funcionalidad próximamente disponible',
              backgroundColor: AppTheme.goldAccent,
              colorText: AppTheme.premiumBlack,
            );
          },
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return _buildSettingsCard(
      title: 'Cuenta',
      icon: Icons.person,
      children: [
        _buildSettingsRow(
          title: 'Editar Perfil',
          subtitle: 'Cambiar información personal',
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          onTap: () {
            Get.snackbar(
              'Editar Perfil',
              'Funcionalidad próximamente disponible',
              backgroundColor: AppTheme.goldAccent,
              colorText: AppTheme.premiumBlack,
            );
          },
        ),
        const Divider(height: 24),
        _buildSettingsRow(
          title: 'Cambiar Contraseña',
          subtitle: 'Actualizar tu contraseña',
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          onTap: () {
            Get.snackbar(
              'Cambiar Contraseña',
              'Funcionalidad próximamente disponible',
              backgroundColor: AppTheme.goldAccent,
              colorText: AppTheme.premiumBlack,
            );
          },
        ),
        const Divider(height: 24),
        _buildSettingsRow(
          title: 'Privacidad',
          subtitle: 'Configuración de privacidad',
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          onTap: () {
            Get.snackbar(
              'Configuración de Privacidad',
              'Funcionalidad próximamente disponible',
              backgroundColor: AppTheme.goldAccent,
              colorText: AppTheme.premiumBlack,
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppInfoSection() {
    return _buildSettingsCard(
      title: 'Acerca de',
      icon: Icons.info,
      children: [
        _buildSettingsRow(
          title: 'Versión',
          subtitle: '1.0.0',
          trailing: const SizedBox(),
        ),
        const Divider(height: 24),
        _buildSettingsRow(
          title: 'Términos y Condiciones',
          subtitle: 'Leer términos de uso',
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          onTap: () {
            Get.snackbar(
              'Términos y Condiciones',
              'Funcionalidad próximamente disponible',
              backgroundColor: AppTheme.goldAccent,
              colorText: AppTheme.premiumBlack,
            );
          },
        ),
        const Divider(height: 24),
        _buildSettingsRow(
          title: 'Política de Privacidad',
          subtitle: 'Leer política de privacidad',
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          onTap: () {
            Get.snackbar(
              'Política de Privacidad',
              'Funcionalidad próximamente disponible',
              backgroundColor: AppTheme.goldAccent,
              colorText: AppTheme.premiumBlack,
            );
          },
        ),
        const Divider(height: 24),
        _buildSettingsRow(
          title: 'Contacto',
          subtitle: 'soporte@courseven.com',
          trailing: Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          onTap: () {
            Get.snackbar(
              'Contacto',
              'Funcionalidad próximamente disponible',
              backgroundColor: AppTheme.goldAccent,
              colorText: AppTheme.premiumBlack,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.goldAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.goldAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsRow({
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return _buildSettingsRow(
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.goldAccent,
      ),
    );
  }
}
