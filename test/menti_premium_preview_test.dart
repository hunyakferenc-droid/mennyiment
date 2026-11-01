import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_premium_renderer.dart';

void main() {
  testWidgets('nine premium material compositions decode and render together', (tester) async {
    tester.view.physicalSize=const Size(1020,1320);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final capture=GlobalKey();
    await tester.pumpWidget(MaterialApp(home:Scaffold(backgroundColor:const Color(0xFF171020),
      body:RepaintBoundary(key:capture,child:Column(children:[
        for(final family in ['boy','girl','neutral']) Row(mainAxisAlignment:MainAxisAlignment.center,children:[
          for(final age in ['young','adult','veteran']) MentiAvatarRenderer(size:320,
            profile:MentiIdentityProfile(visual:MentiVisualProfile({'family':family,'age':age,
              'hair':'$family-${age=='young'?'crop':age=='adult'?'waves':'bob'}',
              'headwear':'none','outfit':age=='young'?'basic':age=='adult'?'street':'cozy'}))),
        ]),
      ])))));
    await tester.runAsync(() async {
      final context=tester.element(find.byType(Scaffold));
      for(final path in MentiPremiumComposition.assets) {await precacheImage(AssetImage(path),context);}
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(),isNull);
    if(Platform.environment['MENTI_CAPTURE']=='1') {
      await tester.runAsync(() async {
      final boundary=capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image=await boundary.toImage();final bytes=await image.toByteData(format:ui.ImageByteFormat.png);
      File('docs/images/menti-final-playable/runtime-nine.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox.shrink());await tester.pump();
  });
}
