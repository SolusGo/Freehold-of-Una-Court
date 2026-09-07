"""Run Library Exile gameplay against a Lua 5.1 Civ V API mock."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".modbuddy/test-deps"))
from lupa.lua51 import LuaRuntime

MOCK = r'''
save, notices = {}, {}
GameInfoTypes={CIVILIZATION_TRENT_LIBRARY_EXILE=100,BUILDING_TRENT_SCHOOL_LIBRARY=200,
 UNIT_TRENT_IPAD_READER=300,BUILDING_TRENT_EXILE_1=401,BUILDING_TRENT_EXILE_2=402,
 BUILDING_TRENT_EXILE_3=403,BUILDING_TRENT_VISITOR_WRITER=404,
 BUILDING_TRENT_VISITOR_HAPPINESS=405,BUILDING_TRENT_VISITOR_CULTURE=406,
 BUILDING_TRENT_READER_CITY=407}
GameDefines={MAX_MAJOR_CIVS=5}
NotificationTypes={NOTIFICATION_GENERIC=1}
Locale={ConvertTextKey=function(key,...) return key end}
Modding={OpenSaveData=function() return {GetValue=function(k) return save[k] end,SetValue=function(k,v) save[k]=v end} end}
function Event()
 local event={callbacks={}}
 event.Add=function(f) event.callbacks[#event.callbacks+1]=f end
 return setmetatable(event,{__call=function(self,...) local result=true;for _,f in ipairs(self.callbacks) do if f(...)==false then result=false end end;return result end})
end
function EventsTable() return setmetatable({}, {__index=function(t,k)local e=Event();rawset(t,k,e);return e end}) end
GameEvents,Events=EventsTable(),EventsTable()
function Iter(items)local i=0;return function()i=i+1;return items[i] end end
function City(id,x,y)
 local city={id=id,x=x,y=y,buildings={}}
 function city:GetID() return self.id end
 function city:GetX() return self.x end
 function city:GetY() return self.y end
 function city:GetNumRealBuilding(kind)return self.buildings[kind] or 0 end
 function city:SetNumRealBuilding(kind,value)self.buildings[kind]=value end
 return city
end
function Unit(kind,x,y)
 local unit={kind=kind,x=x,y=y,dead=false}
 function unit:GetUnitType()return self.kind end
 function unit:GetX()return self.x end
 function unit:GetY()return self.y end
 function unit:IsDead()return self.dead end
 function unit:IsDelayedDeath()return self.dead end
 return unit
end
Players,Teams={},{}
for id=0,4 do
 local p={id=id,alive=true,civ=id==0 and 100 or 99,minor=false,friend={},denouncing={},cities={},units={},science=0,era=0,human=id==0}
 function p:GetID()return self.id end
 function p:IsAlive()return self.alive end
 function p:GetCivilizationType()return self.civ end
 function p:IsHuman()return self.human end
 function p:IsMinorCiv()return self.minor end
 function p:GetTeam()return self.id end
 function p:IsDoF(other)return self.friend[other] or false end
 function p:IsDenouncingPlayer(other)return self.denouncing[other] or false end
 function p:Cities()return Iter(self.cities) end
 function p:Units()return Iter(self.units) end
 function p:GetCapitalCity()return self.cities[1] end
 function p:GetCurrentEra()return self.era end
 function p:GetCivilizationShortDescription()return 'Civilization '..self.id end
 function p:ChangeOverflowResearch(value)self.science=self.science+value end
 function p:AddNotification(kind,body,title)notices[#notices+1]={body=body,title=title} end
 Players[id]=p
 local team={war={}}
 function team:IsAtWar(other)return self.war[other] or false end
 Teams[id]=team
end
function ResetWorld()
 save,notices={},{}
 for id=0,4 do
  local p=Players[id];p.alive=true;p.friend={};p.denouncing={};p.cities={};p.units={};p.science=0;p.era=0;p.civ=id==0 and 100 or 99
  Teams[id].war={}
 end
 local capital=City(1,2,2);capital.buildings[200]=1;Players[0].cities={capital,City(2,4,4)}
end
'''

GAMEPLAY = (ROOT / "Lua/TrentLibraryExile_Gameplay.lua").read_text(encoding="utf-8")
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(MOCK)
lua.execute(GAMEPLAY)


def scenario(name, code):
    lua.execute("ResetWorld()")
    lua.execute(code)
    print("PASS", name)


scenario("zero stacks leaves School Library unmodified", "Events.SequenceGameInitComplete();assert(Players[0].cities[1]:GetNumRealBuilding(401)==0)")
scenario("war and denouncement from one player count once", "Teams[0].war[1]=true;Players[1].denouncing[0]=true;GameEvents.PlayerDoTurn(0);assert(Players[0].cities[1].buildings[401]==1 and save['TRENT_LIBRARY_EXILE_0_STACKS']==1)")
scenario("Exile stacks cap at three and reconcile", "for i=1,4 do Players[i].denouncing[0]=true end;GameEvents.PlayerDoTurn(0);assert(Players[0].cities[1].buildings[403]==1);for i=1,4 do Players[i].denouncing[0]=false end;GameEvents.PlayerDoTurn(1);assert(Players[0].cities[1]:GetNumRealBuilding(403)==0)")
scenario("only School Library cities receive Exile", "Teams[0].war[1]=true;GameEvents.PlayerDoTurn(0);assert(Players[0].cities[1].buildings[401]==1 and Players[0].cities[2]:GetNumRealBuilding(401)==0)")
scenario("first friend becomes permanent active Visitor", "Players[0].friend[2]=true;GameEvents.PlayerDoTurn(0);local a=Players[0].cities[1];local b=Players[0].cities[2];assert(save['TRENT_LIBRARY_EXILE_0_VISITOR']==2 and a.buildings[404]==1 and b.buildings[404]==1 and a.buildings[405]==1 and b:GetNumRealBuilding(405)==0 and a.buildings[406]==1)")
scenario("Visitor expires, cannot be replaced, and renews", "Players[0].friend[2]=true;GameEvents.PlayerDoTurn(0);Players[0].friend[2]=false;Players[0].friend[1]=true;GameEvents.PlayerDoTurn(0);assert(save['TRENT_LIBRARY_EXILE_0_VISITOR']==2 and Players[0].cities[1]:GetNumRealBuilding(404)==0);Players[0].friend[2]=true;GameEvents.PlayerDoTurn(0);assert(Players[0].cities[1].buildings[404]==1)")
scenario("Reader stationed bonus requires School Library and does not stack", "Players[0].units={Unit(300,2,2),Unit(300,2,2),Unit(300,4,4)};GameEvents.PlayerDoTurn(0);assert(Players[0].cities[1].buildings[407]==1 and Players[0].cities[2]:GetNumRealBuilding(407)==0);Players[0].units[1].x=5;Players[0].units[2].x=5;GameEvents.PlayerDoTurn(0);assert(Players[0].cities[1]:GetNumRealBuilding(407)==0)")
scenario("iPad Reader expending grants era-scaled Science", "GameEvents.GreatPersonExpended(0,77,300,2,2);assert(Players[0].science==25);Players[0].era=5;GameEvents.GreatPersonExpended(0,78,300,2,2);assert(Players[0].science==175);GameEvents.GreatPersonExpended(0,79,999,2,2);assert(Players[0].science==175)")
scenario("older two-argument Great Person event is supported", "Players[0].era=7;GameEvents.GreatPersonExpended(0,300);assert(Players[0].science==200)")
scenario("captured dummy buildings are cleaned", "Teams[0].war[1]=true;GameEvents.PlayerDoTurn(0);local taken=Players[0].cities[1];Players[0].cities={Players[0].cities[2]};Players[1].cities={taken};GameEvents.CityCaptureComplete();assert(taken.buildings[401]==0)")

print("10 Library Exile gameplay scenarios passed (actual Lua 5.1 module)")
