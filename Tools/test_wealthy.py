"""Execute the real gameplay Lua in Lua 5.1 with persistent Civ V API mocks."""
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[1]
deps = '.modbuddy/test-deps311' if sys.version_info[:2] == (3,11) else '.modbuddy/test-deps'
sys.path.insert(0,str(ROOT/deps))
from lupa.lua51 import LuaRuntime

MOCK=r'''
gameTurn, speed, save, notices = 0, 100, {}, {}
GameInfoTypes={CIVILIZATION_TRENT_WEALTHY=100,BUILDING_PALACE=200,BUILDING_TRENT_WEALTHY_PALACE=201}
for n=1,8 do GameInfoTypes['BUILDING_TRENT_WEALTHY_LUXURY_'..n]=300+n end
GameDefines={MAX_MAJOR_CIVS=10,MAX_CIV_PLAYERS=12}
Game={GetGameTurn=function()return gameTurn end,GetGameSpeedType=function()return 0 end}
GameInfo={GameSpeeds=setmetatable({},{__index=function()return {TrainPercent=speed} end})}
Modding={OpenSaveData=function()return {GetValue=function(k)return save[k] end,
 SetValue=function(k,v)save[k]=v end} end}
MapModData={}
NotificationTypes={NOTIFICATION_GENERIC=1}
Locale={ConvertTextKey=function(key,...) local s=key;for i=1,select('#',...) do s=s..'|'..tostring(select(i,...)) end;return s end}
function Event() local e={callbacks={}};e.Add=function(f)e.callbacks[#e.callbacks+1]=f end
 return setmetatable(e,{__call=function(t,...) for _,f in ipairs(t.callbacks)do f(...)end end}) end
function ResetEvents() GameEvents={PlayerDoTurn=Event(),TeamSetEra=Event(),CityCaptureComplete=Event(),PlayerCityFounded=Event()};Events={LoadScreenClose=Event()} end
ResetEvents()
function City(id) local c={id=id,b={}}
 function c:GetID()return self.id end
 function c:GetNumRealBuilding(t)return self.b[t] or 0 end
 function c:SetNumRealBuilding(t,n)self.b[t]=n end
 return c end
Players,Teams={},{}
for id=0,11 do
 local p={id=id,civ=id==0 and 100 or 1,alive=true,human=true,gold=100,gpt=5,era=0,cities={City(id*10)}}
 p.capital=p.cities[1]
 function p:GetID()return self.id end
 function p:GetCivilizationType()return self.civ end
 function p:IsAlive()return self.alive end
 function p:IsMinorCiv()return self.id==10 end
 function p:IsBarbarian()return self.id==11 end
 function p:IsHuman()return self.human end
 function p:GetGold()return self.gold end
 function p:ChangeGold(n)self.gold=self.gold+n;assert(self.gold>=0) end
 function p:CalculateGoldRate()return self.gpt end
 function p:GetTeam()return self.id end
 function p:GetCurrentEra()return self.era end
 function p:GetCapitalCity()return self.capital end
 function p:GetCivilizationShortDescription()return 'Civ '..self.id end
 function p:Cities()local i=0;return function()i=i+1;return self.cities[i] end end
 function p:AddNotification(_,body,title)notices[#notices+1]={id=self.id,body=body,title=title} end
 Players[id]=p
 Teams[id]={unmet={},IsHasMet=function(self,id)return not self.unmet[id] end}
end
Players[1].gold=2000;Players[1].gpt=100
function Tick(t)gameTurn=t;GameEvents.PlayerDoTurn(0)end
function Bonus()local h,g,count=0,0,0;for _,p in pairs(Players)do for c in p:Cities()do
 for n=1,8 do local v=c:GetNumRealBuilding(300+n);h=h+n*v;g=g+2*n*v;count=count+v end end end;return h,g,count end
function CheckBonus(h,g)local a,b,c=Bonus();assert(a==h and b==g and c==1)end
'''

SCRIPT=(ROOT/'Lua/TrentWealthy_Gameplay.lua').read_text(encoding='utf-8')


def run():
    scenarios=[
      ('200 Gold conserved, precisely five installments', '', '''
       local total=Players[0].gold+Players[1].gold
       Tick(24);assert(Players[0].gold==100)
       Tick(25);assert(Players[0].gold==200 and Players[1].gold==1900)
       for t=26,30 do Tick(t);Tick(t) end
       assert(Players[0].gold==300 and Players[1].gold==1800)
       Tick(31);assert(Players[0].gold==300)
       assert(Players[0].gold+Players[1].gold==total)
      '''),
      ('reload does not repeat activation or installment', '', '''
       Tick(25);Reload();Tick(25);assert(Players[0].gold==200)
       Tick(26);Reload();Tick(26);assert(Players[0].gold==220)
       for t=27,30 do Tick(t);Reload();Tick(t) end
       assert(Players[0].gold==300 and save.TRENT_WEALTHY_V1_0_NEXT==50)
      '''),
      ('changing, zero and negative GPT still consume five turns','', '''
       Tick(25);Players[1].gpt=-20;Tick(26);assert(Players[0].gold==200)
       Players[1].gpt=0;Tick(27);Players[1].gpt=55;Tick(28)
       Players[1].gpt=100;Tick(29);Tick(30);Tick(31);assert(Players[0].gold==251)
      '''),
      ('insufficient treasury never creates debt','', '''
       Tick(25);Players[1].gold=3;Tick(26)
       assert(Players[1].gold==0 and Players[0].gold==203)
       Tick(27);assert(Players[0].gold==203)
      '''),
      ('major, contact, war, treasury and GPT eligibility','', '''
       Players[2].gold=4000;Players[2].gpt=100;Teams[0].unmet[2]=true
       Players[3].gold=3000;Players[3].gpt=9
       Players[4].gold=2500;Players[4].gpt=100;Players[4].alive=false
       Players[10].gold=99999;Players[10].gpt=100;Players[11].gold=99999;Players[11].gpt=100
       local a=MapModData.TrentWealthy.Targets(Players[0]);assert(#a==1 and a[1]==1)
       Players[1].war=true;Tick(25);assert(Players[1].gold==1900)
      '''),
      ('richest third is ranked before GPT filtering','', '''
       for i=1,9 do Players[i].gold=3000-i*100;Players[i].gpt=i<=3 and 0 or 100 end
       assert(#MapModData.TrentWealthy.Targets(Players[0])==0)
      '''),
      ('top two, deterministic treasury ties','', '''
       for i=1,9 do Players[i].gold=2000;Players[i].gpt=100 end
       local a=MapModData.TrentWealthy.Targets(Players[0]);assert(#a==2 and a[1]==1 and a[2]==2)
       Tick(25);assert(Players[0].gold==300 and Players[3].gold==2000)
      '''),
      ('richest third rounds up and excludes dead and unmet','', '''
       for i=3,9 do Players[i].alive=false end
       Players[2].gold=3000;Players[2].gpt=100
       local a=MapModData.TrentWealthy.Targets(Players[0]);assert(#a==1 and a[1]==2)
      '''),
      ('Marathon interval 75, duration remains five','speed=300', '''
       assert(MapModData.TrentWealthy.Interval()==75)
       Tick(74);assert(Players[0].gold==100);Tick(75)
       for t=76,80 do Tick(t) end;Tick(81)
       assert(Players[0].gold==300 and save.TRENT_WEALTHY_V1_0_NEXT==150)
      '''),
      ('Quick interval rounds to nearest whole turn','speed=67', '''
       assert(MapModData.TrentWealthy.Interval()==17);Tick(16);assert(Players[0].gold==100)
       Tick(17);assert(Players[0].gold==200)
      '''),
      ('no transfer to dead Trent; resurrection resets active cycle','', '''
       Tick(25);Players[0].alive=false;gameTurn=26;GameEvents.PlayerDoTurn(1)
       assert(save.TRENT_WEALTHY_V1_0_REMAINING==0 and Players[0].gold==200)
       Players[0].alive=true;Tick(27);assert(Players[0].gold==200)
       Tick(50);assert(Players[0].gold==295)
      '''),
      ('victim elimination ends its participation in current audit','', '''
       Tick(25);Players[1].alive=false;Tick(26);Players[1].alive=true;Tick(27)
       assert(Players[0].gold==200)
      '''),
      ('no eligible targets consumes cooldown without payments','Players[1].gold=499', '''
       Tick(25);assert(Players[0].gold==100 and save.TRENT_WEALTHY_V1_0_NEXT==50)
       Players[1].gold=2000;Tick(26);assert(Players[0].gold==100)
      '''),
      ('Ancient, Medieval, Information tiers never stack','', '''
       CheckBonus(1,2);Players[0].era=2;GameEvents.TeamSetEra(0,2,true);CheckBonus(3,6)
       Reload();CheckBonus(3,6);Players[0].era=7;GameEvents.TeamSetEra(0,7,true);CheckBonus(8,16)
       Tick(1);CheckBonus(8,16)
      '''),
      ('capital relocation and capture clear stale bonuses','', '''
       local p=Players[0];local old=p.capital;local new=City(77);p.cities[2]=new;p.capital=new
       old.b[200]=1;new.b[200]=1;GameEvents.CityCaptureComplete()
       CheckBonus(1,2);assert(old.b[201]==0 and new.b[201]==1 and new.b[200]==0)
       p.cities={new};Players[1].cities[2]=old;old.b[301]=1;old.b[201]=1
       Players[1].capital.b[200]=1;GameEvents.CityCaptureComplete();CheckBonus(1,2)
       assert(old.b[301]==0 and old.b[201]==0 and Players[1].capital.b[200]==1)
      '''),
      ('pre-capital start and later founding','Players[0].capital=nil;Players[0].cities={}', '''
       local h,g,c=Bonus();assert(c==0);Players[0].cities={City(55)}
       Players[0].capital=Players[0].cities[1];GameEvents.PlayerCityFounded(0);CheckBonus(1,2)
      '''),
      ('UI, era and capture callbacks cannot levy Gold','', '''
       gameTurn=25;Events.LoadScreenClose();GameEvents.TeamSetEra();GameEvents.CityCaptureComplete()
       assert(Players[0].gold==100);Tick(25);assert(Players[0].gold==200)
      '''),
      ('foreign humans receive reports, no double load registration','', '''
       Tick(25);assert(#notices==2);Tick(26);assert(#notices==4)
       LoadAgain();assert(#GameEvents.PlayerDoTurn.callbacks==1)
      '''),
      ('advanced start and future era cap','gameTurn=200;Players[0].era=9', '''
       CheckBonus(8,16);Tick(224);assert(Players[0].gold==100);Tick(225);assert(Players[0].gold==200)
      '''),
      ('absent Wealthy civilization installs no handlers or state','Players[0].civ=1', '''
       assert(#GameEvents.PlayerDoTurn.callbacks==0 and next(save)==nil)
      '''),
    ]
    for title,setup,body in scenarios:
        lua=LuaRuntime(unpack_returned_tuples=True)
        lua.execute(MOCK)
        lua.execute(setup)
        def load_again(): lua.execute(SCRIPT)
        def reload():
            lua.execute('MapModData={};ResetEvents()')
            load_again()
        lua.globals().Reload=reload
        lua.globals().LoadAgain=load_again
        load_again()
        try: lua.execute(body)
        except Exception as e: raise AssertionError(title) from e
        print('PASS:',title)
    print(f'Wealthy gameplay: {len(scenarios)} Lua 5.1 scenarios passed; in-game tests remain manual.')


if __name__=='__main__':run()
