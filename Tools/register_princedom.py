"""Apply only the seventh-civilization registrations to a project XML string.

Text insertion deliberately preserves the user's existing project formatting.
"""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]


def transform(text):
    if '<Name>Princedom Two Masters Panel</Name>' in text:
        return text
    text=text.replace('Six Trent civilizations:', 'Seven Trent civilizations:')
    text=text.replace('Six Community Patch civilizations:', 'Seven Community Patch civilizations:')
    text=text.replace('and the espionage-focused Phone Stealer.',
                      'the espionage-focused Phone Stealer, and the Pupil of Two Masters Princedom.')
    actions=['Princedom/Art/PrinceAtlases.xml',
             'Princedom/SQL/100_Prince_Inherit.sql','Princedom/SQL/101_Prince_Core.sql','Princedom/SQL/102_Prince_Text.sql']
    text=text.replace('    </ModActions>', ''.join(
        f'      <Action>\n        <Set>OnModActivated</Set>\n        <Type>UpdateDatabase</Type>\n        <FileName>{p}</FileName>\n      </Action>\n'
        for p in actions)+'    </ModActions>')
    text=text.replace('    </ModContent>',
        '      <Content>\n        <Type>InGameUIAddin</Type>\n        <Name>Princedom Two Masters Panel</Name>\n'
        '        <Description>Trent mastery, cooldown and adjacent target selection.</Description>\n'
        '        <FileName>Princedom/UI/PrincePanel.xml</FileName>\n      </Content>\n    </ModContent>')
    items=[]
    for p in sorted((ROOT/'Princedom').rglob('*')):
        if p.suffix not in {'.lua','.xml','.sql','.dds'}: continue
        rel=str(p.relative_to(ROOT)).replace('/','\\')
        vfs=p.suffix=='.dds' or p.parent.name=='Lua' or p.name=='PrinceLeaderScene.xml'
        subtype={'.lua':'Lua','.xml':'XML','.sql':'SQL'}.get(p.suffix)
        items.append(f'    <Content Include="{rel}">\n'+
            (f'      <SubType>{subtype}</SubType>\n' if subtype else '')+
            f'      <ImportIntoVFS>{str(vfs)}</ImportIntoVFS>\n    </Content>\n')
    # Insert before the first content ItemGroup's closing tag.
    pos=text.index('  </ItemGroup>',text.index('    <Content Include='))
    return text[:pos]+''.join(items)+text[pos:]


if __name__=='__main__':
    path=ROOT/'UnaCourt.civ5proj'
    path.write_text(transform(path.read_text(encoding='utf-8')),encoding='utf-8')
    print('Registered Princedom in the collection project')
