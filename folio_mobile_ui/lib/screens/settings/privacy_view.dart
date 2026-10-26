import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'settings_screen.i18n.dart';

class PrivacyView extends StatelessWidget {
  const PrivacyView({super.key});

  static void show(BuildContext context) => showDialog(
      context: context,
      builder: (context) => const PrivacyView(),
      barrierDismissible: true);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100.0, horizontal: 32.0),
      child: Material(
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("privacy".i18n),
              ),
              SelectableLinkify(
                text: """
  • A Tinta (továbbiakban: "alkalmazás") egy nem hivatalos, nyílt forráskódú mobilos kliensalkalmazás, segítségével az e-Kréta rendszeréből letöltheted és felhasználóbarát módon megjelenítheted az adataidat. Tanulmányi adataid csak közvetlenül az alkalmazás és a Kréta-szerverek között közlekednek, titkosított kapcsolaton keresztül.

  • A Tinta fejlesztője, valamint az alkalmazás a tanulmányi és személyes adataidat semmilyen célból és semmilyen körülmények között nem másolja, nem tárolja és harmadik félnek nem továbbítja. Ezeket az Educational Development Informatikai Zrt. kezeli, az adatkezeléssel kapcsolatos tájékoztatójukat itt találod: https://tudasbazis.ekreta.hu/pages/viewpage.action?pageId=4065038

  • Azok törlésével vagy módosításával kapcsolatban keresd az osztályfőnöködet vagy az iskolád rendszergazdáját.

  • Az alkalmazás nem gyűjt használati statisztikát és nem küld hibajelentést. Induláskor letölt egy általános beállításfájlt a Firka nyilvános szerveréről (api.firka.app), ehhez semmilyen azonosítót nem küld.

  • Az alkalmazás minden indításakor a GitHub API segítségével ellenőrzi, hogy elérhető-e új verzió (github.com/Pacuka/tinta), és kérésre innen letölti a frissítést.

  • Kérdés vagy hiba esetén nyiss egy bejegyzést (issue-t) itt: https://github.com/Pacuka/tinta/issues

  • A Tinta a Folio (Zan1456), a Firka és a Filc nyílt forráskódú munkájára épül, AGPL-3.0 licenc alatt.
""",
                onOpen: (link) => launchUrl(
                  Uri.parse(link.url),
                  customTabsOptions: CustomTabsOptions(
                    showTitle: true,
                    colorSchemes: CustomTabsColorSchemes(
                      defaultPrams: CustomTabsColorSchemeParams(
                        toolbarColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
