"""Run Phone Stealer gameplay against a Lua 5.1 Civ V API mock."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".modbuddy/test-deps"))
from lupa.lua51 import LuaRuntime


MOCK = r'''
save, notices, gameTurn = {}, {}, 0
local rawTypes={CIVILIZATION_TRENT_PHONE_STEALER=100,UNIT_TRENT_UNA_COURT_BUTLER=200,
 DIPLOMODIFIER_TRENT_STOLE_PHONE=300}
GameInfoTypes=setmetatable(rawTypes,{__index=function(t,k)
 local n=string.match(k,"BUILDING_TRENT_PHONE_STASH_(%d+)")
 if n then return 400+tonumber(n) end
 return nil
end})
GameDefines={MAX_MAJOR_CIVS=4}
GameInfo={GameSpeeds={[0]={TrainPercent=100}}}
Game={GetGameTurn=function()return gameTurn end,GetGameSpeedType=function()return 0 end}
NotificationTypes={NOTIFICATION_GENERIC=1}
Locale={ConvertTextKey=function(key,...)return key end}
MapModData={}
Modding={OpenSaveData=function()return {
 GetValue=function(k)return save[k] end,
 SetValue=function(k,v)save[k]=v end}
end}
function Event()
 local event={callbacks={}}
 event.Add=function(f)event.callbacks[#event.callbacks+1]=f end
 return setmetatable(event,{__call=function(self,...)
  local result=true
  for _,f in ipairs(self.callbacks)do local value=f(...);if value==false then result=false end end
  return result
 end})
end
function EventsTable()return setmetatable({},{__index=function(t,k)local e=Event();rawset(t,k,e);return e end})end
GameEvents,Events,LuaEvents=EventsTable(),EventsTable(),EventsTable()
function Iter(items)local i=0;return function()i=i+1;return items[i] end end
function City(id,x,y,name)
 local city={id=id,x=x,y=y,name=name or ('City '..id),buildings={}}
 function city:GetID()return self.id end
 function city:GetX()return self.x end
 function city:GetY()return self.y end
 function city:GetName()return self.name end
 function city:SetNumRealBuilding(kind,value)self.buildings[kind]=value end
 function city:GetNumRealBuilding(kind)return self.buildings[kind] or 0 end
 return city
end
function Unit(kind,x,y)
 local unit={kind=kind,x=x,y=y,moves=120,jumped=false}
 function unit:GetUnitType()return self.kind end
 function unit:JumpToNearestValidPlot()self.jumped=true return true end
 function unit:SetMoves(value)self.moves=value end
 return unit
end
Players,Teams={},{}
for id=0,3 do
 local p={id=id,alive=true,ever=true,civ=id==0 and 100 or 99,human=id==0,cities={},units={},unitLookup={},spies={},friend={},denouncing={}}
 function p:IsAlive()return self.alive end
 function p:IsEverAlive()return self.ever end
 function p:GetCivilizationType()return self.civ end
 function p:IsHuman()return self.human end
 function p:GetTeam()return self.id end
 function p:Cities()return Iter(self.cities) end
 function p:GetCapitalCity()return self.cities[1] end
 function p:GetEspionageSpies()return self.spies end
 function p:GetUnitByID(unitID)return self.unitLookup[unitID] end
 function p:GetCivilizationShortDescription()return 'Civilization '..self.id end
 function p:GetName()return 'Leader '..self.id end
 function p:IsDoF(other)return self.friend[other] or false end
 function p:IsDenouncingPlayer(other)return self.denouncing[other] or false end
 function p:AddNotification(kind,body,title,x,y)notices[#notices+1]={body=body,title=title,x=x,y=y} end
 function p:InitUnit(kind,x,y)local u=Unit(kind,x,y);self.units[#self.units+1]=u;return u end
 Players[id]=p
 local team={war={},met={}}
 function team:IsAtWar(other)return self.war[other] or false end
 function team:IsHasMet(other)return self.met[other] ~= false end
 Teams[id]=team
end
function ResetWorld()
 save,notices,gameTurn={}, {}, 0
 for id=0,3 do
  local p=Players[id]
  p.alive,p.ever,p.civ,p.human=true,true,id==0 and 100 or 99,id==0
  p.cities={City(id*10+1,id*3+1,id*3+2,'Capital '..id)}
  p.units,p.unitLookup,p.spies,p.friend,p.denouncing={},{},{},{},{}
  Teams[id].war,Teams[id].met={},{}
 end
end
function EstablishSpy(playerID,targetID)
 local city=Players[targetID]:GetCapitalCity()
 Players[playerID].spies={{CityX=city:GetX(),CityY=city:GetY(),IsDiplomat=false,EstablishedSurveillance=true}}
end
ResetWorld()
'''


GAMEPLAY = (ROOT / "Lua/TrentPhoneStealer_Gameplay.lua").read_text(encoding="utf-8")
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(MOCK)
lua.execute(GAMEPLAY)


def scenario(name, code):
    lua.execute("ResetWorld()")
    lua.execute(code)
    print("PASS", name)


scenario(
    "mission requires an established foreign-capital Spy",
    "assert(MapModData.TrentPhoneStealer.StartMission(0,1)==false);EstablishSpy(0,1);assert(MapModData.TrentPhoneStealer.StartMission(0,1)==true)",
)
scenario(
    "eight Standard turns complete a Phone theft",
    "EstablishSpy(0,1);assert(MapModData.TrentPhoneStealer.StartMission(0,1));gameTurn=7;MapModData.TrentPhoneStealer.ProcessMissions(0);assert(MapModData.TrentPhoneStealer.PhoneOwner(1)==-1);gameTurn=8;MapModData.TrentPhoneStealer.ProcessMissions(0);assert(MapModData.TrentPhoneStealer.PhoneOwner(1)==0)",
)
scenario(
    "moving the Spy cancels the mission",
    "EstablishSpy(0,1);MapModData.TrentPhoneStealer.StartMission(0,1);Players[0].spies={};gameTurn=2;MapModData.TrentPhoneStealer.ProcessMissions(0);assert(save['TRENT_PHONE_V1_MISSION_0_1']==-1 and MapModData.TrentPhoneStealer.PhoneOwner(1)==-1)",
)
scenario(
    "one Phone grants the exact Capital yields building",
    "MapModData.TrentPhoneStealer.SetPhoneOwner(1,0);MapModData.TrentPhoneStealer.ProcessMissions(0);assert(Players[0].cities[1]:GetNumRealBuilding(401)==1 and MapModData.TrentPhoneStealer.PhoneCount(0)==1)",
)
scenario(
    "return removes yields and creates thirty-turn protection",
    "MapModData.TrentPhoneStealer.SetPhoneOwner(1,0);MapModData.TrentPhoneStealer.ProcessMissions(0);assert(MapModData.TrentPhoneStealer.ReturnPhone(0,1));assert(MapModData.TrentPhoneStealer.PhoneOwner(1)==-1 and Players[0].cities[1]:GetNumRealBuilding(401)==0);EstablishSpy(0,1);assert(MapModData.TrentPhoneStealer.StartMission(0,1)==false);gameTurn=30;assert(MapModData.TrentPhoneStealer.StartMission(0,1)==true)",
)
scenario(
    "Phone of an eliminated target remains in the Stash",
    "MapModData.TrentPhoneStealer.SetPhoneOwner(1,0);Players[1].alive=false;MapModData.TrentPhoneStealer.ProcessMissions(0);assert(MapModData.TrentPhoneStealer.PhoneOwner(1)==0 and MapModData.TrentPhoneStealer.PhoneCount(0)==1)",
)
scenario(
    "opinion penalty exists only while the victim's Phone is held",
    "MapModData.TrentPhoneStealer.SetPhoneOwner(1,0);assert(MapModData.TrentPhoneStealer.GetDiploModifier(300,1,0)==-50);MapModData.TrentPhoneStealer.ReturnPhone(0,1);assert(MapModData.TrentPhoneStealer.GetDiploModifier(300,1,0)==0)",
)
scenario(
    "AI avoids a close friend",
    "Players[0].human=false;Players[1].friend[0]=true;EstablishSpy(0,1);MapModData.TrentPhoneStealer.ProcessMissions(0);assert(save['TRENT_PHONE_V1_MISSION_0_1']==nil)",
)
scenario(
    "AI begins against a hostile civilization",
    "Players[0].human=false;Players[1].denouncing[0]=true;EstablishSpy(0,1);MapModData.TrentPhoneStealer.ProcessMissions(0);assert(save['TRENT_PHONE_V1_MISSION_0_1']==0)",
)
scenario(
    "captured Butler returns at the Capital with no movement",
    "Players[0].unitLookup[77]=Unit(200,4,4);GameEvents.UnitCaptured(1,9,0,77,true,1);GameEvents.UnitPrekill(0,77,200,4,4,false,1);MapModData.TrentPhoneStealer.ProcessButlerEscapes(0);assert(#Players[0].units==1 and Players[0].units[1].kind==200 and Players[0].units[1].moves==0 and Players[0].units[1].jumped)",
)
scenario(
    "query reports Stash totals and actionable targets",
    "MapModData.TrentPhoneStealer.SetPhoneOwner(1,0);EstablishSpy(0,2);local s={};MapModData.TrentPhoneStealer.Query(0,s);assert(s.enabled and s.count==1 and s.science==2 and s.gold==2 and s.culture==1 and s.happiness==0 and s.total==3);local found=false;for _,r in ipairs(s.targets)do if r.id==2 and r.action=='snatch' then found=true end end;assert(found)",
)

print("11 Phone Stealer gameplay scenarios passed (actual Lua 5.1 module)")
