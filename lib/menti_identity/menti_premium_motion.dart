import 'dart:async';
import 'package:flutter/material.dart';
import '../menti_motion.dart';
import '../menti_experience_settings.dart';
import 'menti_identity.dart';
import 'menti_premium_renderer.dart';

/// A brief eye-frame change, not a continuously ticking animation. Never owns
/// or mutates character data. Pauses with hidden routes, background and reduced
/// motion; previews do not mount this widget.
class MentiPremiumMotion extends StatefulWidget {
  const MentiPremiumMotion({super.key,required this.profile,this.reaction,this.showBackground=true});
  final MentiIdentityProfile profile;
  final String? reaction;
  final bool showBackground;
  @override
  State<MentiPremiumMotion> createState()=>_MentiPremiumMotionState();
}
class _MentiPremiumMotionState extends State<MentiPremiumMotion> with WidgetsBindingObserver {
  Timer? _idle,_reset;
  bool _blink=false,_wink=false,_foreground=true,_enabled=false;
  @override
  void initState(){super.initState();WidgetsBinding.instance.addObserver(this);}
  void _stop(){_idle?.cancel();_reset?.cancel();_idle=null;_reset=null;_blink=false;_wink=false;}
  void _schedule(){
    _idle?.cancel();
    if(!_enabled || !_foreground) return;
    _idle=Timer(const Duration(seconds:7),()=>_expression());
  }
  void _expression({bool wink=false}){
    if(!mounted || !_enabled || !_foreground) return;
    _reset?.cancel();
    setState((){_blink=!wink;_wink=wink;});
    _reset=Timer(Duration(milliseconds:wink?280:140),(){
      if(!mounted) return;
      setState((){_blink=false;_wink=false;});_schedule();
    });
  }
  @override
  void didChangeDependencies(){
    super.didChangeDependencies();
    final enabled=MentiMotionScope.animateOf(context) && MentiExperienceScope.reactionsOf(context);
    if(enabled==_enabled) return;
    _enabled=enabled;
    if(enabled){_schedule();}else{_stop();}
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state){
    _foreground=state==AppLifecycleState.resumed;
    if(_foreground){_schedule();}else{setState(_stop);}
  }
  @override
  void didUpdateWidget(covariant MentiPremiumMotion oldWidget){
    super.didUpdateWidget(oldWidget);
    if(oldWidget.reaction!=widget.reaction && widget.reaction=='funny') _expression(wink:true);
  }
  @override
  void dispose(){_stop();WidgetsBinding.instance.removeObserver(this);super.dispose();}
  @override
  Widget build(BuildContext context)=>MentiPremiumComposition(profile:widget.profile,
    reaction:widget.reaction,showBackground:widget.showBackground,blink:_blink,wink:_wink);
}
