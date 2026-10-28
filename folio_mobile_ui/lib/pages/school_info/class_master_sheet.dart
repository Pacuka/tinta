import 'package:flutter/material.dart';
import 'package:folio_kreta_api/models/class_master.dart';
import 'package:folio_mobile_ui/common/bottom_sheet_menu/rounded_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';

import 'school_info.i18n.dart';

/// Homeroom teacher's name with tap-to-email / tap-to-call rows.
void showClassMasterSheet(BuildContext context, List<ClassMaster> masters) {
  showRoundedModalBottomSheet(
    context,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("class_master".i18n,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6))),
          for (final m in masters) ...[
            const SizedBox(height: 6.0),
            Text(m.name,
                style:
                    const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w800)),
            for (final e in m.emails)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.mail_outline_rounded),
                title: Text(e),
                subtitle: Text("write_email".i18n),
                onTap: () => launchUrl(Uri(scheme: "mailto", path: e)),
              ),
            for (final p in m.phones)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.call_outlined),
                title: Text(p),
                subtitle: Text("call".i18n),
                onTap: () => launchUrl(
                    Uri(scheme: "tel", path: p.replaceAll(RegExp(r"[^0-9+]"), ""))),
              ),
            if (m.emails.isEmpty && m.phones.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text("no_contact".i18n),
              ),
          ],
        ],
      ),
    ),
  );
}
