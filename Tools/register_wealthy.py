"""Append the eighth civilization without reformatting existing project XML."""
from validate_mod import ROOT


def transform(text):
    if 'SQL/110_Wealthy_Inherit.sql' in text:
        return text
    text=text.replace('Seven Trent civilizations:', 'Eight Trent civilizations:')
    text=text.replace('Seven Community Patch civilizations:', 'Eight Community Patch civilizations:')
    text=text.replace('and the Pupil of Two Masters Princedom.',
                      'the Pupil of Two Masters Princedom, and the Wealthy of Una Court.')
    actions=['Art/WealthyTrent/WealthyAtlases.xml','SQL/110_Wealthy_Inherit.sql',
             'SQL/111_Wealthy_Core.sql','SQL/112_Wealthy_Text.sql']
    text=text.replace('    </ModActions>',''.join(
        f'      <Action>\n        <Set>OnModActivated</Set>\n        <Type>UpdateDatabase</Type>\n        <FileName>{p}</FileName>\n      </Action>\n'
        for p in actions)+'    </ModActions>')
    paths=[ROOT/p for p in actions]+[ROOT/'Lua/TrentWealthy_Gameplay.lua']
    paths+=sorted(p for p in (ROOT/'Art/WealthyTrent').glob('*') if p.suffix=='.dds' or p.name=='WealthyLeaderScene.xml')
    items=[]
    for p in paths:
        rel=str(p.relative_to(ROOT)).replace('/','\\')
        vfs=p.suffix in {'.dds','.lua'} or p.name=='WealthyLeaderScene.xml'
        items.append(f'    <Content Include="{rel}">\n      <ImportIntoVFS>{str(vfs)}</ImportIntoVFS>\n    </Content>\n')
    pos=text.index('  </ItemGroup>',text.index('    <Content Include='))
    return text[:pos]+''.join(items)+text[pos:]


if __name__=='__main__':
    path=ROOT/'UnaCourt.civ5proj'
    path.write_text(transform(path.read_text(encoding='utf-8-sig')),encoding='utf-8-sig')
    print('Registered Wealthy in the existing collection')
