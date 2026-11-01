import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mennyiment/menti_identity/menti_identity.dart';
import 'package:mennyiment/menti_identity/menti_avatar_renderer.dart';
import 'package:mennyiment/menti_identity/menti_premium_renderer.dart';
import 'package:mennyiment/menti_identity/menti_premium_atlas.dart';
import 'package:mennyiment/menti_identity/menti_visual_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all material sprites are present and inside unchanged source sheets',(){
    final manifest=jsonDecode(File('test/fixtures/menti_premium_atlases.json').readAsStringSync()) as Map;
    expect(manifest.keys.toSet(),{'bodies','outfits','hair','features','headwear'});
    expect(MentiPremiumAtlas.rects.length,68);
    for(final entry in manifest.entries){
      final data=entry.value as Map;
      final bytes=File(data['asset'] as String).readAsBytesSync();
      expect(bytes.length,data['bytes']);
      var crc=0xffffffff;
      for(final byte in bytes){crc^=byte;
        for(var bit=0;bit<8;bit++){crc=(crc>>1)^((crc&1)==1?0xedb88320:0);}
      }
      expect((crc^0xffffffff)&0xffffffff,data['crc32']);

      for(final sprite in (data['sprites'] as Map).keys){
        final rect=MentiPremiumAtlas.rects['${entry.key}/$sprite']!;
        expect(rect.width,greaterThan(0));expect(rect.height,greaterThan(0));
        expect(rect.left,greaterThanOrEqualTo(0));expect(rect.top,greaterThanOrEqualTo(0));
        expect(rect.right,lessThanOrEqualTo((data['size'] as List)[0]));
        expect(rect.bottom,lessThanOrEqualTo((data['size'] as List)[1]));
      }
    }
    expect(MentiVisualCatalog.options.length,115);
    for(final family in ['boy','girl','neutral']) {
      for(final age in ['young','adult','veteran']) {
        final p=MentiIdentityProfile(visual:MentiVisualProfile({'family':family,'age':age}));
        for(final sprite in MentiPremiumComposition.sprites(p)){expect(MentiPremiumAtlas.rects,contains(sprite));}
      }
    }
  });
  testWidgets('every compatible option changes rendered pixels for all nine identities', (tester) async {
    tester.view.physicalSize=const Size(220,280);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    final boundaryKey=GlobalKey();
    var profile=MentiIdentityProfile();String? reaction;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:StatefulBuilder(builder:(context,setState){
      update=setState;
      return RepaintBoundary(key:boundaryKey,child:MentiAvatarRenderer(
        profile:profile,reaction:reaction,size:200));
    }))));
    await tester.runAsync(() async {
      final context=tester.element(find.byType(Scaffold));
      for(final path in MentiPremiumComposition.assets){await precacheImage(AssetImage(path),context);}
    });
    await tester.pumpAndSettle();
    for(final family in ['boy','girl','neutral']) {
      for(final age in ['young','adult','veteran']) {
        final hashes=<String,Set<int>>{}; final counts=<String,int>{};
        final base=MentiIdentityProfile(visual:MentiVisualProfile({'family':family,'age':age,
          'hair':'$family-crop','headwear':'none'}));
        for(final option in MentiVisualCatalog.options.where((o)=>o.field!='hair'||o.id.startsWith('$family-'))){
          update((){
            profile=MentiPreviewRenderer.previewProfile(base,option);
            reaction=option.field=='reaction'?option.id:null;
          });
          await tester.pumpAndSettle();
          expect(tester.takeException(),isNull,reason:'$family/$age/${option.rewardId}');
          final hash=await tester.runAsync(() async {
            final boundary=boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            final image=await boundary.toImage(pixelRatio:.6);
            final data=await image.toByteData(format:ui.ImageByteFormat.rawRgba);image.dispose();
            var value=2166136261;
            for(final byte in data!.buffer.asUint8List()){value=((value^byte)*16777619)&0xffffffff;}
            return value;
          });
          hashes.putIfAbsent(option.field,()=>{}).add(hash!);
          counts.update(option.field,(n)=>n+1,ifAbsent:()=>1);
        }
        for(final field in counts.keys){
          expect(hashes[field]!.length,counts[field],reason:'$family/$age: each $field option must visibly differ');
        }
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());await tester.pump();
  });
}
