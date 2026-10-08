"""Create the installable collection without ModBuddy; no game files modified.

python Tools/package_mod.py             # refresh checked-in UnaCourt.modinfo
python Tools/package_mod.py --package   # also copy a ready-to-install mod folder
"""
from pathlib import Path
import argparse
import hashlib
import shutil
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
NS={'m':'http://schemas.microsoft.com/developer/msbuild/2003'}


def build(package=False):
    project=ET.parse(ROOT/'UnaCourt.civ5proj')
    prop=project.find('m:PropertyGroup',NS)
    get=lambda key:prop.findtext('m:'+key,namespaces=NS)
    mod=ET.Element('Mod',id=get('Guid'),version=get('ModVersion'))
    properties=ET.SubElement(mod,'Properties')
    for key in ('Name','Teaser','Description','Authors','AffectsSavedGames','MinCompatibleSaveVersion',
                'SupportsSinglePlayer','SupportsMultiplayer','SupportsHotSeat','SupportsMac',
                'ReloadAudioSystem','ReloadLandmarkSystem','ReloadStrategicViewSystem','ReloadUnitSystem'):
        value=get(key)
        if value is not None:
            ET.SubElement(properties,key).text={'true':'1','false':'0'}.get(value.lower(),value)
    dependencies=ET.SubElement(mod,'Dependencies')
    ET.SubElement(dependencies,'Mod',id='d1b6328c-ff44-4b0d-aad7-c657f83610cd',minversion='151',maxversion='999',title='Community Patch')
    files=ET.SubElement(mod,'Files')
    listed={}
    for content in project.findall('.//m:ItemGroup/m:Content',NS):
        filename=content.get('Include').replace('\\','/')
        vfs=content.findtext('m:ImportIntoVFS',default='False',namespaces=NS).lower()=='true'
        listed[filename]=vfs
    for filename,vfs in sorted(listed.items()):
        path=ROOT/filename
        assert path.is_file(),path
        node=ET.SubElement(files,'File',{'md5':hashlib.md5(path.read_bytes()).hexdigest(),'import':str(int(vfs))})
        node.text=filename
    actions=ET.SubElement(mod,'Actions')
    activated=ET.SubElement(actions,'OnModActivated')
    for action in prop.findall('m:ModActions/m:Action',NS):
        kind=action.findtext('m:Type',namespaces=NS)
        ET.SubElement(activated,kind).text=action.findtext('m:FileName',namespaces=NS)
    entrypoints=ET.SubElement(mod,'EntryPoints')
    for content in prop.findall('m:ModContent/m:Content',NS):
        node=ET.SubElement(entrypoints,'EntryPoint',type=content.findtext('m:Type',namespaces=NS),
                           file=content.findtext('m:FileName',namespaces=NS))
        for key in ('Name','Description'):
            ET.SubElement(node,key).text=content.findtext('m:'+key,namespaces=NS)
    ET.indent(mod,space='  ')
    manifest=ROOT/'UnaCourt.modinfo'
    ET.ElementTree(mod).write(manifest,encoding='utf-8',xml_declaration=True)
    if package:
        target=ROOT/'Build/Una Court Civilizations (v 3)'
        target.mkdir(parents=True,exist_ok=True)
        for filename in listed:
            dest=target/filename
            dest.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(ROOT/filename,dest)
        shutil.copy2(manifest,target/manifest.name)
        for filename in ('README.md','Princedom/README.md','Princedom/TESTING.md','Princedom/CP151_NOTES.md'):
            if (ROOT/filename).exists():
                dest=target/filename;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/filename,dest)
        print(f'Installable mod folder: {target}')
    print(f'Manifest: {len(listed)} files, {len(activated)} database actions, {len(entrypoints)} UI entry points')


if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--package',action='store_true')
    build(parser.parse_args().package)
