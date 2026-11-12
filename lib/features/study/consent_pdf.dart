part of carp_study_app;

/// The signed informed consent as a PDF: the consent document (stored already
/// translated) followed by a signature block with name, signature, and date.
// ponytail: built-in Helvetica is Latin-1 only; other scripts need a bundled TTF.
Future<Uint8List> consentPdf(InformedConsentInput input) async {
  final signed = _signedConsent(input.consent);
  final document = signed?.consentDocument;

  final pdf = pw.Document(title: document?.title ?? 'Informed Consent', creator: 'CARP Study App');

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 56, vertical: 64),
      footer: _footer,
      build: (context) => [
        _titleBlock(document?.title ?? 'Informed Consent', input),
        pw.SizedBox(height: 24),
        if (document != null)
          for (final section in document.sections) _section(section)
        else if (!input.consent.trimLeft().startsWith('{'))
          // Old deployments stored plain text in `consent`.
          pw.Paragraph(text: input.consent, style: _body, textAlign: pw.TextAlign.justify)
        else
          // Unparseable JSON - printing it raw would dump the signature bytes.
          pw.Paragraph(text: 'The content of the signed consent document could not be displayed.', style: _body),
        pw.SizedBox(height: 24),
        _signatureBlock(input, signed),
      ],
    ),
  );
  return pdf.save();
}

/// The CARP brand primary color, matching carp_themes_package.
final PdfColor _primary = PdfColor.fromInt(0xff006398);
final PdfColor _grey = PdfColor.fromInt(0xff6e6e73);

const pw.TextStyle _body = pw.TextStyle(fontSize: 11, lineSpacing: 3);
final pw.TextStyle _label = pw.TextStyle(fontSize: 8, color: _grey, letterSpacing: 0.5);

pw.Widget _titleBlock(String title, InformedConsentInput input) => pw.Container(
  width: double.infinity,
  padding: const pw.EdgeInsets.only(bottom: 12),
  decoration: pw.BoxDecoration(
    border: pw.Border(bottom: pw.BorderSide(color: _primary, width: 2)),
  ),
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text('INFORMED CONSENT', style: _label),
      pw.SizedBox(height: 4),
      pw.Text(
        title,
        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _primary),
      ),
      pw.SizedBox(height: 4),
      pw.Text('Signed ${_date(input.signedTimestamp)}', style: pw.TextStyle(fontSize: 10, color: _grey)),
    ],
  ),
);

/// One consent section, laid out as on the consent review screen.
pw.Widget _section(RPConsentSection section) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 14),
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        section.title,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _primary),
      ),
      pw.SizedBox(height: 4),
      pw.Text(section.summary, style: _body, textAlign: pw.TextAlign.justify),
      if (section.content != null && section.content!.isNotEmpty) ...[
        pw.SizedBox(height: 4),
        pw.Text(section.content!, style: _body, textAlign: pw.TextAlign.justify),
      ],
      for (final dataType in section.dataTypes ?? <RPDataTypeSection>[])
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 12, top: 6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(dataType.dataName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text(dataType.dataInformation, style: _body, textAlign: pw.TextAlign.justify),
            ],
          ),
        ),
    ],
  ),
);

/// The drawn signature above a rule, with name, date, and location - like a
/// paper consent form.
pw.Widget _signatureBlock(InformedConsentInput input, RPConsentSignatureResult? signed) {
  final signature = signed?.signature;
  final image = _signatureImage(signature?.signatureImage ?? input.signatureImage);
  final name = (signature?.firstName != null || signature?.lastName != null) ? signature!.fullName : input.name;

  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xfff2f2f7), borderRadius: pw.BorderRadius.circular(4)),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('SIGNATURE', style: _label),
        pw.SizedBox(height: 12),
        if (image != null)
          pw.Container(
            height: 60,
            alignment: pw.Alignment.centerLeft,
            child: pw.Image(pw.MemoryImage(image), fit: pw.BoxFit.contain),
          ),
        pw.Container(width: 240, margin: const pw.EdgeInsets.only(top: 4), color: _grey, height: 0.5),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            pw.Expanded(child: _fact('NAME', name)),
            pw.Expanded(child: _fact('DATE', _date(input.signedTimestamp))),
            if (input.signedLocation != null) pw.Expanded(child: _fact('LOCATION', input.signedLocation!)),
          ],
        ),
        pw.SizedBox(height: 8),
        _fact('PARTICIPANT ID', input.userId),
      ],
    ),
  );
}

pw.Widget _fact(String label, String value) => pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.start,
  children: [
    pw.Text(label, style: _label),
    pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
  ],
);

pw.Widget _footer(pw.Context context) => pw.Container(
  alignment: pw.Alignment.centerRight,
  margin: const pw.EdgeInsets.only(top: 16),
  child: pw.Text('${context.pageNumber} / ${context.pagesCount}', style: pw.TextStyle(fontSize: 9, color: _grey)),
);

String _date(DateTime timestamp) => DateFormat.yMMMMd().add_Hm().format(timestamp.toLocal());

/// The signed consent behind [consent], or null if it is not RP consent JSON -
/// old deployments stored plain text there.
RPConsentSignatureResult? _signedConsent(String consent) {
  try {
    // Registers the RP fromJson functions; without it parsing fails until RP UI has run.
    ResearchPackage.ensureInitialized();
    final jsonMap = json.decode(consent) as Map<String, dynamic>;
    _downgradeUnknownSectionTypes(jsonMap);
    return RPConsentSignatureResult.fromJson(jsonMap);
  } catch (error) {
    warning('Informed consent is not a signed RP consent document - $error');
    return null;
  }
}

/// Map section types unknown to this app's research_package version to
/// `Custom`, so a consent signed against a newer RP still renders.
void _downgradeUnknownSectionTypes(Map<String, dynamic> jsonMap) {
  final known = RPConsentSectionType.values.map((type) => type.name).toSet();
  final sections = (jsonMap['consentDocument'] as Map<String, dynamic>?)?['sections'];
  if (sections is! List) return;
  for (final section in sections.whereType<Map<String, dynamic>>()) {
    if (!known.contains(section['type'])) {
      section['type'] = RPConsentSectionType.Custom.name;
      section['title'] ??= '';
    }
  }
}

/// The signature PNG - stored by RP as `Uint8List.toString()`, not base64.
Uint8List? _signatureImage(String? image) {
  if (image == null || image.isEmpty || image == 'null') return null;
  try {
    if (image.startsWith('[')) {
      return Uint8List.fromList(RegExp(r'\d+').allMatches(image).map((byte) => int.parse(byte[0]!)).toList());
    }
    return base64Decode(image);
  } catch (error) {
    warning('Could not decode the informed consent signature image - $error');
    return null;
  }
}
