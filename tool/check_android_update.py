"""Read-only update preflight for two real APKs. Never installs/uninstalls anything."""
import argparse,hashlib,json,re,subprocess
from pathlib import Path

def decision(installed,incoming):
 if installed['applicationId']!=incoming['applicationId']:
  return 'separate-app', 'Different package: separate Android sandbox; no automatic data transfer.'
 if installed['certificateSha256']!=incoming['certificateSha256']:
  return 'blocked-signature', 'Signing certificates differ. Preserve the installed app/data; rebuild with its original key or use a separate test device.'
 if incoming['versionCode']<installed['versionCode']:
  return 'blocked-downgrade', 'Incoming versionCode is lower; no downgrade override is allowed.'
 return 'compatible-signature', 'Same package/certificate and nondecreasing versionCode. Back up first; runtime upgrade remains a separate device test.'

def inspect(apk,tools):
 def run(tool,*args):return subprocess.check_output([str(tools/tool),*map(str,args)],text=True)
 sig=run('apksigner','verify','--print-certs',apk)
 badging=run('aapt','dump','badging',apk).splitlines()[0]
 cert=re.search(r'certificate SHA-256 digest: ([0-9a-f]{64})',sig)
 package=re.search(r"name='([^']+)' versionCode='(\d+)'",badging)
 if not cert or not package:raise ValueError('APK signature/package metadata cannot be verified')
 return {'applicationId':package[1],'versionCode':int(package[2]),'certificateSha256':cert[1],'sha256':hashlib.sha256(apk.read_bytes()).hexdigest()}

def main():
 p=argparse.ArgumentParser();p.add_argument('--installed-apk',type=Path,required=True);p.add_argument('--incoming-apk',type=Path,required=True);p.add_argument('--build-tools',type=Path,required=True);p.add_argument('--output',type=Path,required=True);a=p.parse_args()
 old,new=inspect(a.installed_apk,a.build_tools),inspect(a.incoming_apk,a.build_tools)
 status,help=decision(old,new)
 a.output.parent.mkdir(parents=True,exist_ok=True)
 a.output.write_text(json.dumps({'installed':old,'incoming':new,'status':status,'guidance':help,'readOnly':True,'actualInstallAttempted':False},indent=2)+'\n',encoding='utf-8')
 print(status+': '+help)
if __name__=='__main__':main()
