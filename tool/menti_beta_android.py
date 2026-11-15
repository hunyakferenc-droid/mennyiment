"""Isolated REVIEW Android configuration; normal checkout is never modified."""
REVIEW_APPLICATION_ID = 'com.example.mennyiment.review'

def prepare_review_android(work):
 gradle=work/'android/app/build.gradle.kts'
 text=gradle.read_text(encoding='utf-8')
 old='applicationId = "com.example.mennyiment"'
 if text.count(old)!=1: raise ValueError('Unexpected application ID configuration; preserve the normal app.')
 gradle.write_text(text.replace(old, 'applicationId = "'+REVIEW_APPLICATION_ID+'"'),encoding='utf-8')
 manifest=work/'android/app/src/main/AndroidManifest.xml'
 text=manifest.read_text(encoding='utf-8').replace('android:label="MennyiMent?"','android:label="Menti Beta REVIEW"').replace('android:name=".MainActivity"','android:name="com.example.mennyiment.MainActivity"').replace('@drawable/menti_launcher','@drawable/menti_review_launcher')
 manifest.write_text(text,encoding='utf-8')
 # Existing Menti artwork, with a persistent purple/gold R badge. No character edit.
 icon=work/'android/app/src/main/res/drawable/menti_review_launcher.xml'
 icon.parent.mkdir(parents=True,exist_ok=True)
 icon.write_text('''<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
 <item android:width="48dp" android:height="48dp" android:gravity="center" android:drawable="@drawable/menti_launcher"/>
 <item android:width="20dp" android:height="20dp" android:gravity="bottom|right">
 <vector android:width="28dp" android:height="28dp" android:viewportWidth="28" android:viewportHeight="28">
 <path android:fillColor="#542080" android:strokeColor="#FFD166" android:strokeWidth="2" android:pathData="M1,1H27V27H1Z"/>
 <path android:fillColor="#FFD166" android:pathData="M8,6H16Q22,6 22,12Q22,16 17,17L23,23H18L12,17H12V23H8ZM12,10V13H16Q18,13 18,12Q18,10 16,10Z"/>
 </vector></item></layer-list>
''',encoding='utf-8')

