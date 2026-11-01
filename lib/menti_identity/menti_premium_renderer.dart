import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'menti_identity.dart';
import 'menti_visual_catalog.dart';
import 'menti_premium_atlas.dart';

/// Original high-resolution material sheets are shared by the image cache.
/// Runtime crops avoid hundreds of duplicate files and preserve source pixels.
class MentiPremiumSprite extends StatelessWidget {
  const MentiPremiumSprite({super.key, required this.sprite, this.color, this.sourcePart});
  final String sprite;
  final Color? color;
  final Rect? sourcePart;
  @override
  Widget build(BuildContext context) {
    final group = sprite.split('/').first;
    final original = MentiPremiumAtlas.rects[sprite]!;
    final part = sourcePart;
    final rect = part == null ? original : Rect.fromLTWH(
      original.left+part.left*original.width,original.top+part.top*original.height,
      part.width*original.width,part.height*original.height);
    return Image(image: AssetImage('${MentiPremiumAtlas.root}$group.png'),
      excludeFromSemantics: true, gaplessPlayback: true,
      frameBuilder: (context, child, frame, sync) => frame == null ? const SizedBox.shrink() :
        LayoutBuilder(builder: (context, c) => ClipRect(child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: c.maxWidth, maxWidth: double.infinity,
          minHeight: c.maxHeight, maxHeight: double.infinity,
          child: Transform.translate(offset: Offset(-rect.left * c.maxWidth / rect.width,
            -rect.top * c.maxHeight / rect.height), child: SizedBox(
              width: _sizes[group]!.width * c.maxWidth / rect.width,
              height: _sizes[group]!.height * c.maxHeight / rect.height,
              child: color == null ? child : ColorFiltered(
                colorFilter: group == 'hair' ? const ColorFilter.matrix([.22,.52,.06,0,62, .22,.52,.06,0,62, .22,.52,.06,0,68, 0,0,0,1,0]) : ColorFilter.mode(color!, BlendMode.softLight), child: child))),
        ))),
      fit: BoxFit.fill);
  }
  static const _sizes = {'bodies': Size(1121,1403), 'outfits':Size(1254,1254),
    'hair':Size(1774,887), 'features':Size(2172,724), 'headwear':Size(1254,1254)};
}

class MentiPremiumComposition extends StatelessWidget {
  const MentiPremiumComposition({super.key, required this.profile, this.reaction,
    this.showBackground = true, this.blink = false, this.wink = false});
  final MentiIdentityProfile profile;
  final String? reaction;
  final bool showBackground, blink, wink;

  static const previewCrops = <String,List<double>>{
    'style':[85,200,150,65], 'face':[65,112,190,62], 'eyes':[60,60,200,90],
    'hair':[0,0,320,205], 'headwear':[0,0,320,145], 'outfit':[25,155,270,245],
    'glasses':[50,65,220,85], 'neck':[80,165,160,75], 'held':[0,220,320,120],
    'detail':[75,90,170,90], 'back':[20,150,280,180], 'accent':[65,160,190,225],
    'background':[0,0,320,400], 'aura':[0,0,320,400], 'reaction':[0,0,320,400],
  };
  static List<String> layers(MentiIdentityProfile p,{String? reaction,bool showBackground=true}) {
    String asset(String f)=>MentiVisualCatalog.root+resolve(p,f).asset;
    return [
      if(showBackground) asset('background'),asset('aura'),
      if(resolve(p,'back').id!='none') asset('back'),
      '${MentiPremiumAtlas.root}bodies.png','${MentiPremiumAtlas.root}hair.png',
      '${MentiPremiumAtlas.root}outfits.png',asset('style'),'${MentiPremiumAtlas.root}features.png',
      for(final field in ['detail','neck']) if(resolve(p,field).id!='none') asset(field),
      if(resolve(p,'headwear').id!='none') '${MentiPremiumAtlas.root}headwear.png',
      for(final field in ['glasses','held']) if(resolve(p,field).id!='none') asset(field),
      if(reaction!=null) MentiVisualCatalog.root+MentiVisualCatalog.resolve('reaction',reaction).asset,
    ];
  }

  static const sheets = ['bodies','outfits','hair','features','headwear'];
  static List<String> get assets => [for(final sheet in sheets) '${MentiPremiumAtlas.root}$sheet.png'];
  static MentiVisualOption resolve(MentiIdentityProfile p,String f) => MentiVisualCatalog.resolve(
    f,p.visual.value(f),family: f=='hair' ? MentiVisualCatalog.resolve('family',p.visual.value('family')).id:null);
  static List<String> sprites(MentiIdentityProfile p) => [
    'bodies/${resolve(p,'family').id}-${resolve(p,'age').id}',
    'outfits/${resolve(p,'outfit').id}', 'hair/${resolve(p,'hair').id}',
    'features/face:${resolve(p,'face').id}', 'features/eyes:${resolve(p,'eyes').id}',
    if(resolve(p,'headwear').id!='none') 'headwear/${resolve(p,'headwear').id}',
  ];
  @override
  Widget build(BuildContext context) {
    String id(String f)=>resolve(profile,f).id;
    final family=id('family'), age=id('age');
    final headWidth=(family=='girl' ? .49 : family=='neutral' ? .55 : .52) *
      (age=='adult' ? .93 : age=='veteran' ? 1.04 : 1);
    final outfitWidth=(family=='girl' ? .60 : family=='neutral' ? .70 : .66) +
      (age=='veteran' ? .035 : age=='adult' ? -.015 : 0);
    final outfitTop=age=='adult' ? .375 : age=='veteran' ? .395 : .405;
    final outfitHeight=.985-outfitTop;
    final eyeTop=age=='adult' ? .145 : age=='veteran' ? .15 : .17;
    final mouthScale=age=='adult' ? .82 : age=='veteran' ? .90 : 1.0;
    final mouthTop=age=='adult' ? .28 : age=='veteran' ? .29 : .305;
    final hx=(1-headWidth)/2;
    final hair=id('hair').split('-').last;
    final longHair=hair=='braid' || (family=='girl' && ['waves','curls','crest'].contains(hair));
    final accent = <String,Color>{'violet':const Color(0xFF9551D8),'blue':const Color(0xFF468DE0),
      'mint':const Color(0xFF73D6B5),'rose':const Color(0xFFE679A4),'orange':const Color(0xFFFFA02C)}[id('accent')];
    final hrect=Rect.fromLTWH(hx-.035,.005,headWidth+.07,longHair ? .46:.34);
    final eyes=blink ? 'blink' : wink ? 'wink' : id('eyes');
    Widget sprite(String s,Rect r,{Color? color,Rect? sourcePart}) => Positioned.fromRect(rect:
      Rect.fromLTWH(r.left*320,r.top*400,r.width*320,r.height*400),
      child:s.startsWith('hair/') ? ClipPath(clipper:_HairFaceClipper(
        Rect.fromLTWH((hx+.055-r.left)/r.width,(eyeTop+.01-r.top)/r.height,
          (headWidth-.11)/r.width,.235/r.height)),child:MentiPremiumSprite(sprite:s,color:color,sourcePart:sourcePart))
        : MentiPremiumSprite(sprite:s,color:color,sourcePart:sourcePart));
    Widget vector(String field, {Rect? target}) {
      final o=resolve(profile,field);
      final path=MentiVisualCatalog.root+o.asset;
      if(target==null) return Positioned.fill(child:SvgPicture.asset(path,key:ValueKey(path),fit:BoxFit.fill));
      final crop=MentiVisualCatalog.previewCrops[field]!;
      return Positioned(left:target.left*320,top:target.top*400,
        width:target.width*320,height:target.height*400,
        child:ClipRect(child:OverflowBox(alignment:Alignment.topLeft,
          minWidth:0,maxWidth:double.infinity,minHeight:0,maxHeight:double.infinity,
          child:Transform.translate(offset:Offset(-crop[0]*target.width*320/crop[2],
            -crop[1]*target.height*400/crop[3]),
            child:SizedBox(width:320*target.width*320/crop[2],height:400*target.height*400/crop[3],
              child:SvgPicture.asset(path,key:ValueKey(path),fit:BoxFit.fill))))));
    }
    return FittedBox(fit:BoxFit.fill,child:SizedBox(width:320,height:400,
      child:Stack(clipBehavior:Clip.hardEdge,children:[
        if(showBackground) vector('background'),vector('aura'),
        if(id('back')!='none') vector('back',target:const Rect.fromLTWH(.12,.40,.76,.37)),
        // Base skin remains behind equipment; feet are hidden under fitted shoes.
        Positioned.fill(child:ClipPath(clipper:_BodyClipper(),child:Stack(children:[
          sprite('bodies/$family-$age',const Rect.fromLTWH(.20,.04,.60,.93)),
        ]))),
        if(longHair) sprite('hair/${id('hair')}',hrect,color:age=='veteran'?const Color(0xFFE3DFE8):null),
        for(final right in [false,true]) sprite('bodies/$family-$age',
          Rect.fromLTWH(right ? (1+outfitWidth)/2-.135 : (1-outfitWidth)/2+.02,
            outfitTop+outfitHeight*.38,.115,.14),
          sourcePart:Rect.fromLTWH(right ? .75 : 0,.56,.25,.20)),
        sprite('outfits/${id('outfit')}',Rect.fromLTWH((1-outfitWidth)/2,outfitTop,outfitWidth,outfitHeight),color:accent),
        vector('style',target:const Rect.fromLTWH(.37,.53,.26,.10)),
        sprite('features/face:${id('face')}',Rect.fromLTWH(.5-.14*mouthScale,mouthTop,.28*mouthScale,.105*mouthScale)),
        sprite('features/eyes:$eyes',Rect.fromLTWH(hx+.07,eyeTop,headWidth-.14,age=='young' ? .155 : .14)),
        if(!longHair) sprite('hair/${id('hair')}',hrect,color:age=='veteran'?const Color(0xFFE3DFE8):null),
        if(id('detail')!='none') vector('detail',target:const Rect.fromLTWH(.28,.28,.44,.09)),
        if(id('neck')!='none') vector('neck',target:const Rect.fromLTWH(.33,.43,.34,.13)),
        if(id('headwear')!='none') sprite('headwear/${id('headwear')}',switch(id('headwear')){
          'headphones'=>Rect.fromLTWH(hx-.03,.07,headWidth+.06,.30),
          'hood'=>Rect.fromLTWH(hx-.04,.045,headWidth+.08,.40),
          'party-hat'=>const Rect.fromLTWH(.34,0,.32,.20),
          _=>Rect.fromLTWH(hx-.025,.005,headWidth+.05,.20),
        }),
        if(id('glasses')!='none') vector('glasses',target:Rect.fromLTWH(hx+.055,.215,headWidth-.11,.105)),
        if(id('held')!='none') vector('held',target:const Rect.fromLTWH(.08,.59,.84,.25)),
        if(reaction!=null) Positioned.fill(child:SvgPicture.asset(MentiVisualCatalog.root+
          MentiVisualCatalog.resolve('reaction',reaction!).asset,key:ValueKey(MentiVisualCatalog.root+
          MentiVisualCatalog.resolve('reaction',reaction!).asset),fit:BoxFit.fill)),
      ])));
  }
}
class _BodyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size)=>Path()
    ..addRect(Rect.fromLTWH(0,0,size.width,size.height*.41))
    ..addRect(Rect.fromLTWH(size.width*.32,size.height*.40,size.width*.36,size.height*.50));
  @override
  bool shouldReclip(_BodyClipper oldClipper)=>false;
}

class _HairFaceClipper extends CustomClipper<Path> {
  const _HairFaceClipper(this.face);
  final Rect face;
  @override
  Path getClip(Size size)=>Path()..fillType=PathFillType.evenOdd
    ..addRect(Offset.zero & size)
    ..addOval(Rect.fromLTWH(face.left*size.width,face.top*size.height,
      face.width*size.width,face.height*size.height));
  @override
  bool shouldReclip(_HairFaceClipper oldClipper)=>face!=oldClipper.face;
}
