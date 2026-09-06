"""Exercise actual gameplay Lua in an isolated Civ V API mock (Lua 5.1)."""
import sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'.modbuddy/test-deps'))
from lupa.lua51 import LuaRuntime

MOCK=r'''
turn, roll, speed, rewardCalls = 0, 99, 0, 0
save, notices = {}, {}
GameInfoTypes = {CIVILIZATION_TRENT_SOFT_KITTY=100, UNIT_TRENT_HOPELESS_ROMANTIC=200,
 BUILDING_TRENT_COMFORT_ROOM=300, PROMOTION_TRENT_REPERCUSSION_COMBAT=400,
 PROMOTION_TRENT_REPERCUSSION_MOVEMENT=401, BUILDING_TRENT_REPERCUSSION_DUMMY=500,
 BUILDING_TRENT_COMFORT_RECOVERY_DUMMY=501, BUILDING_TRENT_MUSIC_DUMMY=502,
 GREAT_WORK_SLOT_MUSIC=1, DOMAIN_AIR=2, MISSION_ONE_SHOT_TOURISM=700}
for n=1,15 do GameInfoTypes['BUILDING_TRENT_REPERCUSSION_PROD_'..n]=600+n end
MajorCivApproachTypes={MAJOR_CIV_APPROACH_FRIENDLY=0,MAJOR_CIV_APPROACH_NEUTRAL=1,
 MAJOR_CIV_APPROACH_GUARDED=2,MAJOR_CIV_APPROACH_DECEPTIVE=3,MAJOR_CIV_APPROACH_HOSTILE=4,
 MAJOR_CIV_APPROACH_AFRAID=5,MAJOR_CIV_APPROACH_WAR=6}
GameDefines={MAX_MAJOR_CIVS=4,MAX_CIV_PLAYERS=6}
Game={GetGameTurn=function() return turn end,GetActivePlayer=function() return 0 end,
 GetGameSpeedType=function() return speed end,Rand=function(n,label) return roll end}
GameInfo={GameSpeeds={[0]={TrainPercent=100,CulturePercent=100},[1]={TrainPercent=67,CulturePercent=67},
 [2]={TrainPercent=150,CulturePercent=150},[3]={TrainPercent=300,CulturePercent=300}},Leaders={}}
Locale={ConvertTextKey=function(key) return key end}
NotificationTypes={NOTIFICATION_GENERIC=1}
Modding={OpenSaveData=function() return {GetValue=function(k) return save[k] end,SetValue=function(k,v) save[k]=v end} end}
Map={PlotDistance=function(x,y,a,b) return math.max(math.abs(x-a),math.abs(y-b)) end}
function Event()
 local t={callbacks={}}
 t.Add=function(f) t.callbacks[#t.callbacks+1]=f end
 return setmetatable(t,{__call=function(self,...) local result=true
  for _,f in ipairs(self.callbacks) do if f(...)==false then result=false end end
  return result end})
end
function NewEvents() return setmetatable({}, {__index=function(t,k) local e=Event();rawset(t,k,e);return e end}) end
function ResetHooks() GameEvents,Events,LuaEvents=NewEvents(),NewEvents(),NewEvents();update=nil end
ResetHooks()
function UnaCourt_RegisterUpdate(f) update=f end
function Iter(list) local i=0;return function() i=i+1; return list[i] end end
function City(id,x,y)
 local c={id=id,x=x,y=y,buildings={},music=0}
 function c:GetID() return self.id end
 function c:GetX() return self.x end
 function c:GetY() return self.y end
 function c:GetNumRealBuilding(k) return self.buildings[k] or 0 end
 function c:SetNumRealBuilding(k,n) self.buildings[k]=n end
 function c:GetNumGreatWorksFilled(slot) assert(slot==1); return self.music end
 return c
end
function Unit(id,kind,military,x,y)
 local u={id=id,kind=kind,military=military,domain=0,x=x or 0,y=y or 0,promos={},dead=false,moves=120,born=0,blast=400}
 function u:GetID() return self.id end
 function u:GetUnitType() return self.kind end
 function u:IsCombatUnit() return self.military end
 function u:GetDomainType() return self.domain end
 function u:GetX() return self.x end
 function u:GetY() return self.y end
 function u:IsHasPromotion(k) return self.promos[k] or false end
 function u:SetHasPromotion(k,v) self.promos[k]=v end
 function u:IsDelayedDeath() return self.dead end
 function u:IsDead() return self.dead end
 function u:IsInCombat() return false end
 function u:IsEmbarked() return false end
 function u:MovesLeft() return self.moves end
 function u:GetGameTurnCreated() return self.born end
 function u:GetTourismBlastStrength() return self.blast end
 function u:Kill(delayed,owner) self.dead=true;self.kills=(self.kills or 0)+1 end
 return u
end
Players,Teams={},{ }
for i=0,5 do
 local p={id=i,alive=true,human=i==0,civ=i==0 and 100 or 99,era=0,approach=1,
 friend={},cities={},units={},culture=0,tourism={},minor=i>=4,ally=-1,influence={},modifier=0,turnActive=true}
 function p:IsAlive() return self.alive end
 function p:GetCivilizationType() return self.civ end
 function p:IsHuman() return self.human end
 function p:IsTurnActive() return self.turnActive end
 function p:IsMinorCiv() return self.minor end
 function p:IsBarbarian() return false end
 function p:GetTeam() return self.id end
 function p:IsDoF(id) return self.friend[id] or false end
 function p:GetMajorCivApproach(id) assert(id==0);return self.approach end
 function p:GetCurrentEra() return self.era end
 function p:GetCivilizationShortDescription() return 'Civ '..self.id end
 function p:GetLeaderType() return self.id end
 function p:Cities() return Iter(self.cities) end
 function p:Units() return Iter(self.units) end
 function p:GetUnitByID(id) for _,u in ipairs(self.units) do if u.id==id then return u end end end
 function p:AddNotification(kind,body,title) notices[#notices+1]={title=title,body=body} end
 function p:ChangeJONSCulture(n) self.culture=self.culture+n;rewardCalls=rewardCalls+1 end
 function p:ChangeInfluenceOnPlayer(id,n,mod,scale) assert(not mod and not scale);self.tourism[id]=(self.tourism[id] or 0)+n end
 function p:GetAlly() return self.ally end
 function p:ChangeMinorCivFriendshipWithMajor(id,n) self.influence[id]=(self.influence[id] or 0)+n end
 function p:GetTourismModifierWith(id) return self.modifier end
 function p:GetJONSCultureEverGenerated() return self.culture end
 Players[i]=p; GameInfo.Leaders[i]={Description='Leader '..i}
 local team={war={},met={[0]=true,[1]=true,[2]=true,[3]=true,[4]=true,[5]=true}}
 function team:IsHasMet(id) return self.met[id] or false end
 function team:IsAtWar(id) return self.war[id] or false end
 Teams[i]=team
end
Players[0].cities={City(0,0,0)}
Players[1].cities={City(1,3,0)}
Players[0].units={Unit(10,1,true)}
Players[4].ally=1
function Query(unit) local r={};LuaEvents.TrentSoftKittyQuery(0,unit or -1,r);return r end
function Row(target,unit) local r=Query(unit);for _,v in ipairs(unit and r.romantics or r.targets) do if v.id==target then return v end end end
function Request(target,unit)
 local r=Row(target,unit);if not r then return end
 LuaEvents.TrentSoftKittyRequest(0,target,unit or -1,r.culture,r.tourism,r.risk)
end
'''

code=(ROOT/'Lua/TrentSoftKitty_Gameplay.lua').read_text(encoding='utf-8')
passed=0
def run(name,body,reload=False):
    global passed
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    lua.execute(code)
    if reload:
        before,after=body.split('-- RELOAD --')
        lua.execute(before)
        lua.execute('ResetHooks()')
        lua.execute(code)
        lua.execute(after)
    else:
        lua.execute(body)
    passed+=1
    print('PASS',name)

run('all audience risks and era rewards',r'''
local rewards={60,30,23,23,15,30};local risks={0,10,25,25,50,10}
for approach=0,5 do Players[1].approach=approach;local r=Row(1);assert(r.culture==rewards[approach+1]);assert(r.risk==risks[approach+1]) end
Players[0].era=7;Players[1].approach=0;assert(Row(1).culture==480 and Row(1).tourism==320)
Players[1].approach=4;Players[0].friend[1]=true;assert(Row(1).risk==0)
''')
run('success, allied influence and duplicate request protection',r'''
Players[1].approach=0;Request(1);assert(Players[0].culture==60 and Players[0].tourism[1]==40)
assert(Players[4].influence[0]==5 and Players[5].influence[0]==nil)
Request(1);assert(rewardCalls==1 and Query().cooldown==15)
''')
run('failed song, Ex assignment, no rewards and cooldown',r'''
roll=0;Request(1);local q=Query();assert(q.recovery==5 and q.cooldown==15 and q.ex==1 and rewardCalls==0)
assert(Players[0].cities[1]:GetNumRealBuilding(615)==1)
assert(Players[0].cities[1]:GetNumRealBuilding(500)==1 and Players[0].units[1]:IsHasPromotion(400))
Players[1].approach=0;assert(Row(1).risk==15 and Row(1).culture==75)
Request(2);assert(Query().ex==1)
''')
run('save/load preserves cooldown Ex and recovery without yields',r'''
roll=0;Request(1);turn=2
-- RELOAD --
assert(Query().cooldown==13 and Query().recovery==3 and Query().ex==1 and rewardCalls==0)
assert(Players[0].cities[1]:GetNumRealBuilding(615)==1)
''',True)
run('comfort mitigation capped, music local, recovery culture',r'''
roll=0;Request(1)
for n=2,17 do Players[0].cities[n]=City(n,n,0) end
for n=1,3 do Players[0].cities[n].buildings[300]=1 end
Players[0].cities[1].music=2;Players[0].cities[4].music=9
GameEvents.CityConstructed(0);assert(Query().penalty==12)
assert(Players[0].cities[1].buildings[612]==1 and Players[0].cities[1].buildings[615]==0)
assert(Players[0].cities[1]:GetNumRealBuilding(502)==2 and Players[0].cities[4]:GetNumRealBuilding(502)==0)
assert(Players[0].cities[1]:GetNumRealBuilding(501)==1 and Players[0].cities[4]:GetNumRealBuilding(501)==0)
for n=1,17 do Players[0].cities[n].buildings[300]=1 end
GameEvents.CityConstructed(0);assert(Query().penalty==0)
for n=1,15 do assert(Players[0].cities[1]:GetNumRealBuilding(600+n)==0) end
''')
run('trained movement only, aircraft/civilian/purchase exclusions, full expiration',r'''
roll=0;Request(1)
for n=11,15 do Players[0].units[#Players[0].units+1]=Unit(n,1,n~=12) end
Players[0]:GetUnitByID(13).domain=2
GameEvents.CityTrained(0,0,11,false,false)
GameEvents.CityTrained(0,0,12,false,false);GameEvents.CityTrained(0,0,13,false,false)
GameEvents.CityTrained(0,0,14,true,false);GameEvents.CityTrained(0,0,15,false,true)
for n=10,15 do assert(Players[0]:GetUnitByID(n):IsHasPromotion(401)==(n==11)) end
turn=5;GameEvents.PlayerDoTurn(0);assert(Query().recovery==0 and Query().cooldown==10)
for _,u in ipairs(Players[0].units) do assert(not u:IsHasPromotion(400) and not u:IsHasPromotion(401)) end
for n=1,15 do assert(Players[0].cities[1]:GetNumRealBuilding(600+n)==0) end
assert(Players[0].cities[1].buildings[500]==0)
''')
run('captured cities and transferred units cleaned',r'''
roll=0;Request(1);local c=Players[0].cities[1];Players[0].cities={};Players[2].cities={c}
GameEvents.CityCaptureComplete(0,false,0,0,2);assert(c.buildings[615]==0 and c.buildings[500]==0)
local u=Players[0].units[1];u.promos[401]=true;Players[0].units={};Players[2].units={u}
GameEvents.UnitCaptured();update(1);assert(not u:IsHasPromotion(400) and not u:IsHasPromotion(401))
''')
run('target validation and stale confirmation rejected',r'''
Teams[0].war[1]=true;assert(Row(1)==nil);Teams[0].war[1]=false
Teams[0].met[1]=false;assert(Row(1)==nil);Teams[0].met[1]=true
Players[1].alive=false;assert(Row(1)==nil);Players[1].alive=true
assert(Row(0)==nil and Row(4)==nil)
local r=Row(1);Players[1].approach=0
LuaEvents.TrentSoftKittyRequest(0,1,-1,r.culture,r.tourism,r.risk);assert(rewardCalls==0)
Players[0].turnActive=false;Request(1);assert(rewardCalls==0)
''')
run('musician rewards consumption Ex bonus and repeat protection',r'''
local u=Unit(20,200,false,2,0);Players[0].units[2]=u
save.TRENT_SOFTKITTY_0_EX_PLAYER=1;Players[1].approach=0
local row=Row(1,20);assert(row.culture==100 and row.tourism==600 and row.risk==0)
Request(1,20);assert(u.dead and u.kills==1 and Players[0].culture==100 and Players[0].tourism[1]==600)
LuaEvents.TrentSoftKittyRequest(0,1,20,100,600,0);assert(rewardCalls==1)
assert(Query().cooldown==0)
''')
run('musician adjacency and Hostile duration refresh without stacking',r'''
local u=Unit(20,200,false,0,0);Players[0].units[2]=u;assert(Row(1,20)==nil)
u.x=2;Players[1].approach=4;roll=0;Request(1,20);assert(Query().ex==1 and Query().recovery==5 and rewardCalls==1)
turn=2;Players[0].units[3]=Unit(21,200,false,2,0);Request(1,21)
assert(Query().recovery==5 and Players[0].cities[1].buildings[615]==1 and Query().ex==1)
turn=7;GameEvents.PlayerDoTurn(0);assert(Query().recovery==0)
''')
run('all four game speeds',r'''
local durations={15,10,23,45};local recovery={5,3,8,15};local cultures={60,40,90,180}
for s=0,3 do
 speed=s;turn=100*s;save.TRENT_SOFTKITTY_0_COOLDOWN_END=0;save.TRENT_SOFTKITTY_0_REPERCUSSION_END=0
 Players[1].approach=0;assert(Row(1).culture==cultures[s+1]);roll=99;Request(1);assert(Query().cooldown==durations[s+1])
 save.TRENT_SOFTKITTY_0_COOLDOWN_END=0;Players[1].approach=4;roll=0;Request(1);assert(Query().recovery==recovery[s+1])
 save.TRENT_SOFTKITTY_0_EX_PLAYER=-1
end
''')
run('AI chooses friendly audience and concert with no duplicate turn rewards',r'''
Players[0].human=false;Players[1].approach=4;Players[2].approach=0;Players[3].approach=2
Players[2].cities={City(2,3,0)};Players[0].units[2]=Unit(20,200,false,2,0)
GameEvents.PlayerDoTurn(0);assert(Players[0].tourism[2]==540 and Players[0].units[2].dead)
local count=rewardCalls;GameEvents.PlayerDoTurn(0);assert(rewardCalls==count)
''')
print(f'{passed} Soft Kitty gameplay scenarios passed (actual Lua 5.1 module)')
