import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

class AboutSupportScreen extends StatelessWidget {
  const AboutSupportScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('No se pudo abrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            const Text(
              "ACERCA DE Y SOPORTE",
              style: TextStyle(fontFamily: 'Pricedown', fontSize: 28),
            ),
          ],
        ),
      ),
      body: SizedBox.expand(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              if (isDesktop) ...[
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildSectionCard(
                          title: "ACERCA DE",
                          content: _buildAboutContent(isDesktop),
                          isDesktop: isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSectionCard(
                          title: "APÓYAME",
                          content: _buildSupportContent(isDesktop),
                          isDesktop: isDesktop,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _buildSectionCard(
                          title: "CONTACTO Y BUGS",
                          content: _buildContactContent(context, isDesktop),
                          isDesktop: isDesktop,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSectionCard(
                          title: "AGRADECIMIENTOS Y CRÉDITOS",
                          content: _buildCreditsGrid(isDesktop),
                          isDesktop: isDesktop,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                _buildSectionCard(
                  title: "ACERCA DE",
                  content: _buildAboutContent(isDesktop),
                  isDesktop: isDesktop,
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: "APÓYAME",
                  content: _buildSupportContent(isDesktop),
                  isDesktop: isDesktop,
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: "CONTACTO Y BUGS",
                  content: _buildContactContent(context, isDesktop),
                  isDesktop: isDesktop,
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: "AGRADECIMIENTOS Y CRÉDITOS",
                  content: _buildCreditsGrid(isDesktop),
                  isDesktop: isDesktop,
                ),
              ],

              const SizedBox(height: 16),
              _buildSectionCard(
                title: "DESARROLLADO POR",
                content: _buildDevCard(isDesktop),
                isDesktop: isDesktop,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget content,
    required bool isDesktop,
    double? minHeight,
  }) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'HouseScript',
              fontSize: isDesktop ? 30 : 24,
              color: const Color(0xFFFFFFFF),
            ),
          ),
          const Divider(color: Colors.white10, height: 24),
          content,
        ],
      ),
    );
  }

  Widget _buildAboutContent(bool isDesktop) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          color: const Color(0xFFE0E0E0),
          fontSize: isDesktop ? 18 : 16,
          height: 1.5,
        ),
        children: [
          const TextSpan(
            style: TextStyle(fontFamily: 'Chalet'),
            text:
                "Este proyecto fue desarrollado con el fin de ofrecer una solución intuitiva a todos los jugadores de ",
          ),
          TextSpan(
            text: "Grand Theft Auto ",
            style: TextStyle(
              fontFamily: 'Pricedown',
              color: const Color(0xFFFFFFFF),
              fontSize: isDesktop ? 20 : 18,
            ),
          ),
          TextSpan(
            text: "Online",
            style: TextStyle(
              fontFamily: 'Pricedown',
              color: const Color.fromARGB(255, 192, 12, 12),
              fontSize: isDesktop ? 20 : 18,
            ),
          ),
          const TextSpan(
            style: TextStyle(fontFamily: 'Chalet'),
            text:
                " que deseen llevar un mejor control de sus propiedades y vehículos, además de servir como una lista para conseguir un gran logro: ",
          ),
          const TextSpan(
            style: TextStyle(
              fontFamily: 'Chalet',
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
            ),
            text:
                "Ser el rey de Los Santos y tener en tus manos la totalidad de vehículos disponibles en el estado de San Andreas.",
          ),
        ],
      ),
    );
  }

  Widget _buildSupportContent(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Si mi trabajo fue de tu agrado y deseas apoyarme de forma monetaria, puedes hacerlo a través de Ko-Fi o Mercado Pago (en caso que vivas en Latinoamérica):",
          style: TextStyle(
            color: Colors.white70,
            fontSize: isDesktop ? 18 : 16,
            fontFamily: 'Chalet',
          ),
        ),
        const SizedBox(height: 16),
        _buildSupportButton(
          "Ko-fi",
          "assets/logos/kofi.png",
          () => _launchURL('https://ko-fi.com/devsansan'),
          isDesktop,
        ),
        const SizedBox(height: 8),
        _buildSupportButton(
          "Mercado Pago",
          "assets/logos/mercadopago.png",
          () => _launchURL('https://link.mercadopago.com.mx/devsansan'),
          isDesktop,
        ),
      ],
    );
  }

  Widget _buildSupportButton(
    String label,
    String asset,
    VoidCallback onTap,
    bool isDesktop,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 16 : 14,
                fontFamily: 'Chalet',
              ),
            ),
            Image.asset(
              asset,
              height: 24,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.payments_outlined, color: Colors.white24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactContent(BuildContext context, bool isDesktop) {
    return Column(
      children: [
        _buildContactItem(
          Icons.bug_report,
          "Reportar un bug",
          () => _showContactOptions(context, "Reporte de Bug - V1.0.1"),
          isDesktop,
        ),
        _buildContactItem(
          Icons.lightbulb_outline,
          "Buzón de sugerencias",
          () => _showContactOptions(context, "Sugerencia de Mejora"),
          isDesktop,
        ),
        _buildContactItem(
          Icons.alternate_email,
          "Correo de contacto",
          () => _showContactOptions(context, "Contacto General"),
          isDesktop,
        ),
        _buildContactItem(
          Icons.share,
          "Redes Sociales Alternas",
          () => _launchURL("https://linktr.ee/s4nsan_"),
          isDesktop,
        ),
      ],
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    VoidCallback onTap,
    bool isDesktop,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.white54, size: isDesktop ? 24 : 20),
      title: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Chalet',
          fontSize: isDesktop ? 16 : 14,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.white24,
        size: 18,
      ),
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildCreditsGrid(bool isDesktop) {
    final credits = [
      {
        "name": "DurtyFree",
        "desc": "ESTRUCTURA BASE Y ARCHIVOS DE DATOS.",
        "url": "https://github.com/DurtyFree",
        "logo": "assets/logos/github.png",
      },
      {
        "name": "GTA Base",
        "desc": "PRECIOS Y MÉTODOS DE OBTENCIÓN.",
        "url": "https://www.gtabase.com",
        "logo": "assets/logos/gtabase.png",
      },
      {
        "name": "GTA Wiki",
        "desc": "GALERÍA DE IMÁGENES Y DATOS.",
        "url": "https://gta.fandom.com/es/wiki/Grand_Theft_Encyclopedia",
        "logo": "assets/logos/fandom.png",
      },
      {
        "name": "Flutter",
        "desc": "PAQUETES Y HERRAMIENTAS DEV.",
        "url": "https://flutter.dev",
        "logo": "assets/logos/flutter.png",
      },
      {
        "name": "DaFont",
        "desc": "FUENTE PRICEDOWN ORIGINAL.",
        "url": "https://www.dafont.com/pricedown.font",
        "logo": "assets/logos/dafont.png",
      },
      {
        "name": "FontsGeek",
        "desc": "FUENTE SIGNPAINTER.",
        "url": "https://fontsgeek.com/fonts/SignPainter-HouseScript-Regular",
        "logo": "assets/logos/fontsgeek.png",
      },
      {
        "name": "GoogleFonts",
        "desc": "FUENTE SCIENCE GOTHIC.",
        "url": "https://github.com/googlefonts/science-gothic",
        "logo": "assets/logos/github.png",
      },
      {
        "name": "OnlineFonts",
        "desc": "FUENTE CHALET.",
        "url": "https://online-fonts.com/fonts/chalet",
        "logo": "assets/logos/onlinefonts.png",
      },
    ];

    if (isDesktop) {
      return Table(
        children: [
          for (var i = 0; i < credits.length; i += 2)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 4, bottom: 8),
                  child: _buildCreditItem(
                    credits[i]['name']!,
                    credits[i]['desc']!,
                    credits[i]['logo']!,
                    () => _launchURL(credits[i]['url']!),
                    isDesktop,
                  ),
                ),
                if (i + 1 < credits.length)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: _buildCreditItem(
                      credits[i + 1]['name']!,
                      credits[i + 1]['desc']!,
                      credits[i + 1]['logo']!,
                      () => _launchURL(credits[i + 1]['url']!),
                      isDesktop,
                    ),
                  )
                else
                  const SizedBox(),
              ],
            ),
        ],
      );
    }
    return Column(
      children: credits
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildCreditItem(
                item['name']!,
                item['desc']!,
                item['logo']!,
                () => _launchURL(item['url']!),
                isDesktop,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCreditItem(
    String name,
    String description,
    String logoPath,
    VoidCallback onTap,
    bool isDesktop,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Chalet',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      fontFamily: 'HouseScript',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Image.asset(
              logoPath,
              height: 18,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.open_in_new,
                color: Colors.white24,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevCard(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border.all(color: Colors.white10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isDesktop ? 120 : 100,
            height: isDesktop ? 120 : 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
              image: const DecorationImage(
                image: AssetImage('assets/images/avatar.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 20),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "SANSAN",
                  style: TextStyle(
                    fontFamily: 'Pricedown',
                    fontSize: isDesktop ? 36 : 28,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "DESARROLLADOR DE SOFTWARE",
                  style: TextStyle(
                    fontFamily: 'HouseScript',
                    color: const Color.fromARGB(255, 125, 126, 124),
                    fontSize: isDesktop ? 18 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.start,
                  spacing: 2,
                  runSpacing: 8,
                  children: [
                    Text(
                      "Arte por @JessyShio:",
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: isDesktop ? 14 : 10,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'Chalet',
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildSocialIcon(
                      'assets/icons/x.svg',
                      () => _launchURL('https://x.com/jessyshio'),
                      isDesktop,
                      color: Colors.white,
                    ),
                    _buildSocialIcon(
                      'assets/icons/instagram.svg',
                      () => _launchURL('https://www.instagram.com/jessyshio'),
                      isDesktop,
                    ),
                    _buildSocialIcon(
                      'assets/icons/tumblr.svg',
                      () => _launchURL('https://www.tumblr.com/je-shi'),
                      isDesktop,
                    ),
                    _buildSocialIcon(
                      'assets/icons/deviantart.svg',
                      () => _launchURL('https://www.deviantart.com/jezzypamda'),
                      isDesktop,
                    ),
                    _buildSocialIcon(
                      'assets/icons/bluesky.svg',
                      () => _launchURL('https://bsky.app/profile/jessyshio.bsky.social'),
                      isDesktop,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(
    String svgPath,
    VoidCallback onTap,
    bool isDesktop, {
    Color? color,
  }) {
    final double iconSize = isDesktop ? 30 : 25;

    return Tooltip(
      message: "Ver red social",
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 4.0 : 8.0),
          child: SvgPicture.asset(
            svgPath,
            width: iconSize,
            height: iconSize,
            colorFilter: color != null
                ? ColorFilter.mode(color, BlendMode.srcIn)
                : null,
          ),
        ),
      ),
    );
  }

  Future<void> _copyEmailToClipboard(BuildContext context, String email) async {
    await Clipboard.setData(ClipboardData(text: email));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Dirección de correo copiada al portapapeles",
            style: TextStyle(fontFamily: 'Chalet', fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFF39FF14),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showContactOptions(BuildContext context, String subject) {
    const String email = 'dev.sansan@protonmail.com';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Colors.white10),
        ),
        title: const Text(
          "MÉTODO DE CONTACTO",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Pricedown',
            fontSize: 24,
          ),
        ),
        content: const Text(
          "¿Cómo deseas contactar al soporte técnico?",
          style: TextStyle(color: Colors.white70, fontFamily: 'Chalet'),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final Uri uri = Uri(
                scheme: 'mailto',
                path: email,
                query: 'subject=${Uri.encodeComponent(subject)}',
              );
              await launchUrl(uri);
            },
            child: const Text(
              "ABRIR CORREO",
              style: TextStyle(color: Colors.white54, fontFamily: 'Chalet'),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF39FF14),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _copyEmailToClipboard(context, email);
            },
            child: const Text(
              "COPIAR DIRECCIÓN",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'Chalet',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
