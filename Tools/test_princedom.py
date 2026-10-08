"""Execute the real Princedom backend in Lua 5.1 against a strict API mock.

Run with a Python matching your installed Lupa, or install it locally with:
python -m pip install --target .modbuddy/test-deps311 lupa==2.8
"""
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(ROOT/'.modbuddy/test-deps311'),str(ROOT/'.modbuddy/test-deps')]
from lupa.lua51 import LuaRuntime

MOCK=r'''
save,turn,speed,nextID,queue,alerts,failOwner={ },0,0,100,{ },{ },nil
function iter(t) local i=0;return function() i=i+1;return t[i] end end
function Event()
 local e={callbacks={}}
 e.Add=function(f)e.callbacks[#e.callbacks+1]=f end
 return setmetatable(e,{__call=function(self,...)
  local result=nil
  for _,f in ipairs(self.callbacks) do local v=f(...);if v~=nil then result=v end end
  return result
 end})
end
function eventTable()return setmetatable({},{__index=function(t,k)local e=Event();t[k]=e;return e end})end
GameEvents,Events,LuaEvents=eventTable(),eventTable(),eventTable()
Events.GameplayAlertMessage.Add(function(text)alerts[#alerts+1]=text end)
GameInfoTypes={CIVILIZATION_PRINCE_UNA=1,UNIT_PRINCE_TRENT=10,UNIT_WARRIOR=11,
 PROMOTION_PRINCE_IDENTITY=20,PROMOTION_PRINCE_BORROWED=21,PROMOTION_PRINCE_SHELL=22,
 DOMAIN_LAND=0,UNITAI_ATTACK=0,BUILDING_PRINCE_FANFIC=40,BUILDING_PRINCE_FANFIC_ACTIVE=41}
for i,n in ipairs({80,82,85,88,90})do GameInfoTypes['PROMOTION_PRINCE_RESIST_'..n]=25+i end
local promos={};for i=20,35 do promos[#promos+1]={ID=i} end
GameInfo={GameSpeeds={[0]={Type='GAMESPEED_STANDARD',TrainPercent=100},
 [1]={Type='GAMESPEED_QUICK',TrainPercent=67},[2]={Type='GAMESPEED_EPIC',TrainPercent=150},
 [3]={Type='GAMESPEED_MARATHON',TrainPercent=300},[4]={Type='CUSTOM',TrainPercent=200}},
 Units=setmetatable({[10]={Combat=12},[11]={Combat=8},[12]={Combat=10},[13]={Combat=25},[14]={Combat=5,RangedCombat=16}},
 {__index=function()return {Combat=8}end}),UnitPromotions=function()return iter(promos)end}
Game={GetGameTurn=function()return turn end,GetElapsedGameTurns=function()return turn end,
 GetGameSpeedType=function()return speed end,GetActivePlayer=function()return 0 end}
GameDefines={MAX_MAJOR_CIVS=3,BARBARIAN_PLAYER=2,MOVE_DENOMINATOR=60}
CommandTypes={COMMAND_DELETE=0,COMMAND_GIFT=1,COMMAND_UPGRADE=2,COMMAND_AUTOMATE=3}
MissionTypes={MISSION_MOVE_TO=0}
Locale={ConvertTextKey=function(k,...)return k end}
Modding={OpenSaveData=function()return {GetValue=function(k)return save[k]end,SetValue=function(k,v)save[k]=v end}end}
function UnaCourt_QueueDeferredRestore(f) queue[#queue+1]=f end
function Flush()local tasks=queue;queue={};for _,f in ipairs(tasks)do f()end end
plots={}
function Plot(x,y)
 local key=x..':'..y
 if not plots[key] then
  local p={x=x,y=y,city=false,water=false,visible=true,owner=-1}
  function p:GetX()return self.x end;function p:GetY()return self.y end
  function p:IsCity()return self.city end;function p:IsWater()return self.water end
  function p:IsImpassable()return false end;function p:GetOwner()return self.owner end
  function p:IsVisible()return self.visible end
  function p:Units()local t={};for _,owner in pairs(Players or {})do for _,u in pairs(owner.units)do
   if u.x==x and u.y==y and not u.dead then t[#t+1]=u end end end;return t end
  function p:GetNumUnits()return #self:Units() end
  function p:GetUnit(i)return self:Units()[i+1]end
  plots[key]=p
 end
 return plots[key]
end
Map={GetPlot=Plot,PlotDistance=function(x,y,a,b)return math.max(math.abs(x-a),math.abs(y-b),math.abs(x-a+y-b))end}
Map.PlotXYWithRangeCheck=function(x,y,dx,dy,r)if Map.PlotDistance(x,y,x+dx,y+dy)<=r then return Plot(x+dx,y+dy)end end
local directions={{1,0},{0,1},{-1,1},{-1,0},{0,-1},{1,-1}}
Map.PlotDirection=function(x,y,d)local v=directions[d+1];return Plot(x+v[1],y+v[2])end
Teams={}
for i=0,2 do Teams[i]={war=true,IsAtWar=function(self,other)return self.war and other~=i end}end
function Unit(owner,kind,x,y)
 nextID=nextID+1
 local u={owner=owner,id=nextID,kind=kind,x=x,y=y,damage=0,xp=125,level=1,moves=120,
  promos={},name='Test',script='foreign:data',domain=0,combat=true,cargo=0,attacks=0}
 function u:GetOwner()return self.owner end;function u:GetID()return self.id end
 function u:GetUnitType()return self.kind end;function u:GetUnitAIType()return 0 end
 function u:GetX()return self.x end;function u:GetY()return self.y end
 function u:GetPlot()return Plot(self.x,self.y)end
 function u:IsDead()return self.dead or false end;function u:IsDelayedDeath()return self.delayed or false end
 function u:GetDamage()return self.damage end;function u:SetDamage(n)self.damage=n end
 function u:GetExperienceTimes100()return self.xp end;function u:SetExperienceTimes100(n)self.xp=n end
 function u:GetLevel()return self.level end;function u:SetLevel(n)self.level=n end
 function u:GetMoves()return self.moves end;function u:SetMoves(n)self.moves=n end
 function u:MaxMoves()return 120 end
 function u:IsOutOfAttacks()return self.moves<=0 or self.attacks>=1 end
 function u:SetMadeAttack(b)self.attacks=b and self.attacks+1 or 0 end
 function u:GetNameNoDesc()return self.name end;function u:GetName()return self.name end
 function u:SetName(n)self.name=n end;function u:GetScriptData()return self.script end
 function u:SetScriptData(s)self.script=s end;function u:GetFacingDirection()return 0 end
 function u:IsHasPromotion(n)return self.promos[n] or false end
 function u:SetHasPromotion(n,b)assert(n,'undefined promotion');self.promos[n]=b end
 function u:IsEmbarked()return self.embarked or false end;function u:IsCargo()return self.isCargo or false end
 function u:GetCargo()return self.cargo end;function u:IsCombatUnit()return self.combat end
 function u:GetDomainType()return self.domain end;function u:IsInvisible()return self.invisible or false end
 function u:GetBaseCombatStrength()return GameInfo.Units[self.kind].Combat or 0 end
 function u:GetBaseRangedCombatStrength()return GameInfo.Units[self.kind].RangedCombat or 0 end
 function u:GetMaxHitPoints()return 100 end
 function u:JumpToNearestValidPlot()return not self.stranded end
 function u:PushMission(_,x,y)self.x=x;self.y=y;self.moves=0;GameEvents.UnitSetXY(self.owner,self.id)end
 function u:Kill(delay,killer)
  GameEvents.UnitPrekill(self.owner,self.id,self.kind,self.x,self.y,delay,killer)
  if delay then self.delayed=true else self.dead=true;Players[self.owner].units[self.id]=nil end
 end
 function u:Convert(old,isUpgrade)
  self.damage=old.damage;self.xp=old.xp;self.level=old.level;self.moves=old.moves
  for k,v in pairs(old.promos)do self.promos[k]=v end
  GameEvents.UnitConverted(old.owner,self.owner,old.id,self.id,isUpgrade)
  old:Kill(true,-1)
 end
 return u
end
function City(monument)
 local c={buildings={[40]=monument and 1 or 0}}
 function c:GetNumRealBuilding(k)return self.buildings[k] or 0 end
 function c:SetNumRealBuilding(k,n)self.buildings[k]=n end
 return c
end
Players={}
for id=0,2 do
 local p={id=id,units={},cities={City(true),City(false)},alive=true,human=id==0}
 function p:GetCivilizationType()return self.id==0 and 1 or 2 end
 function p:GetID()return self.id end;function p:IsAlive()return self.alive end
 function p:IsTurnActive()return true end;function p:IsHuman()return self.human end
 function p:GetTeam()return self.id end;function p:IsBarbarian()return self.id==2 end
 function p:Units()local a={};for _,u in pairs(self.units)do if not u.dead and not u.delayed then a[#a+1]=u end end;return iter(a)end
 function p:Cities()return iter(self.cities)end;function p:GetStartingPlot()return Plot(0,0)end
 function p:GetUnitByID(n)return self.units[n]end
 function p:InitUnit(kind,x,y)
  if failOwner==self.id then return nil end
  local u=Unit(self.id,kind,x,y);self.units[u.id]=u;GameEvents.UnitCreated(self.id,u.id,kind,x,y);return u
 end
 function p:KillCities()self.cities={} end
 Players[id]=p
end
Players[0]:InitUnit(11,0,0)
target=Players[1]:InitUnit(12,1,0)
barbarian=Players[2]:InitUnit(12,0,1)
function Count(owner)local n=0;for _ in Players[owner]:Units()do n=n+1 end;return n end
'''


def runtime():
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    def include(name):lua.execute((ROOT/'Princedom/Lua'/name).read_text(encoding='utf-8'))
    lua.globals().include=include
    include('PrinceMain.lua')
    return lua


def scenario(name,code):
    lua=runtime()
    lua.execute(code)
    print('PASS:',name)


def run():
    for path in (ROOT/'Princedom').rglob('*.lua'):
        LuaRuntime().execute('assert(loadstring(...))',path.read_text(encoding='utf-8'))
    scenarios=[
      ('one opening hero, ordinary Warrior removed', 'assert(Count(0)==1 and Prince.Body(0):GetUnitType()==10);Prince.Initialize(0);assert(Count(0)==1)'),
      ('unique cannot train, gift or disband','local u=Prince.Body(0);assert(GameEvents.PlayerCanTrain(0,10)==false);assert(GameEvents.PlayerCanTrain(0,11)==true);assert(GameEvents.PlayerCanGiftUnit(0,1,u.id)==false);assert(GameEvents.PlayerCanDisbandUnit(0,u.id)==false)'),
      ('additional Trent becomes ordinary military without cloning identity','Players[0]:InitUnit(10,2,0);Flush();assert(Count(0)==2);local heroes=0;for u in Players[0]:Units()do if u.kind==10 then heroes=heroes+1 end end;assert(heroes==1 and Prince.State(0).fallen~=1)'),
      ('possession and separate progression','assert(Prince.Activate(0,"possess",1,target.id));local s=Prince.State(0);assert(s.possession==1 and s.swap==0 and s.readyTurn==8 and s.expires==1);assert(Prince.Body(0).owner==0 and Count(0)==2 and Count(1)==0)'),
      ('Barbarians support both techniques','assert(Prince.Activate(0,"possess",2,barbarian.id));Prince.End(0);turn=8;Prince.Body(0):SetMoves(120);local b;for u in Players[2]:Units()do b=u end;assert(Prince.Activate(0,"swap",2,b.id));assert(Prince.State(0).swap==1)'),
      ('shared cooldown prevents chaining','assert(Prince.Activate(0,"possess",1,target.id));assert(not Prince.Activate(0,"swap",2,barbarian.id));Prince.End(0);Prince.Body(0):SetMoves(120);assert(not Prince.Activate(0,"swap",2,barbarian.id));assert(Prince.State(0).swap==0)'),
      ('invalid category, city, embarked and invisible targets','target.combat=false;assert(not Prince.Validate(0,"possess",target));target.combat=true;target.domain=1;assert(not Prince.Validate(0,"possess",target));target.domain=0;target.embarked=true;assert(not Prince.Validate(0,"possess",target));target.embarked=false;target:GetPlot().city=true;assert(not Prince.Validate(0,"possess",target));target:GetPlot().city=false;target.invisible=true;assert(not Prince.Validate(0,"possess",target));assert(Prince.State(0).possession==0)'),
      ('strength uses higher ranged base and independent mastery','target.kind=14;assert(not Prince.Validate(0,"possess",target));Prince.State(0).possession=6;assert(Prince.Validate(0,"possess",target));assert(not Prince.Validate(0,"swap",target));Prince.State(0).swap=12;target.kind=13;assert(Prince.Validate(0,"swap",target))'),
      ('offensive getter is pure and role-specific','Prince.Activate(0,"possess",1,target.id);local u=Prince.Borrowed(0);GameEvents.BattleStarted();GameEvents.BattleJoined(0,u.id,0,false);assert(GameEvents.BattleDamageDelta(0,50)==-17);assert(GameEvents.BattleDamageDelta(0,50)==-17);assert(GameEvents.BattleDamageDelta(1,50)==0);GameEvents.BattleFinished();assert(GameEvents.BattleDamageDelta(0,50)==0)'),
      ('native armor and city bombard resistance','Prince.State(0).swap=12;assert(Prince.Activate(0,"swap",1,target.id));local b=Prince.Body(0);assert(b:IsHasPromotion(GameInfoTypes.PROMOTION_PRINCE_RESIST_90));GameEvents.BattleStarted();GameEvents.BattleJoined(2,999,0,true);GameEvents.BattleJoined(b.owner,b.id,1,false);assert(GameEvents.BattleDamageDelta(0,50)==-45);assert(GameEvents.BattleDamageDelta(0,50)==-45)'),
      ('swap ownership, movement and action vetoes','assert(Prince.Activate(0,"swap",1,target.id));local b=Prince.Body(0);assert(b.owner==1 and b.moves==0);assert(GameEvents.CanMoveInto(1,b.id,0,-1,true)==false);assert(GameEvents.CanMoveInto(1,b.id,0,-1,false)==true);GameEvents.UnitSetXY(1,b.id);assert(GameEvents.CanMoveInto(1,b.id,0,-1,false)==false);assert(GameEvents.UnitCanPillage(1,b.id)==false);assert(GameEvents.UnitCanRangeAttackAt(1,b.id)==false);assert(GameEvents.CanHaveAnyUpgrade(1,b.id)==false)'),
      ('possessing body immobilized, borrowed cannot embark or upgrade','Prince.Activate(0,"possess",1,target.id);local b,u=Prince.Body(0),Prince.Borrowed(0);assert(GameEvents.CanMoveInto(0,b.id,1,-1,false)==false);Plot(2,0).water=true;assert(GameEvents.CanMoveInto(0,u.id,2,0,false)==false);assert(GameEvents.CanDoCommand(0,u.id,2)==false)'),
      ('return preserves current damage, fractional XP, gained promotions, position and script','target.damage=31;target.moves=0;Prince.Activate(0,"possess",1,target.id);local u=Prince.Borrowed(0);assert(u.damage==31 and u.moves==0 and u.xp==125);u.damage=44;u.xp=397;u.promos[35]=true;u.script="updated:data";u.x=3;Prince.End(0);local r;for v in Players[1]:Units()do r=v end;assert(r.damage==44 and r.xp==397 and r.promos[35] and r.script=="updated:data" and r.x==3 and r.moves==0);assert(Count(0)==1 and Count(1)==1)'),
      ('Monument bonuses do not stack and end immediately','Prince.Activate(0,"possess",1,target.id);Prince.Bonuses(0);Prince.Bonuses(0);assert(Players[0].cities[1].buildings[41]==1 and Players[0].cities[2].buildings[41]==0);Prince.End(0);assert(Players[0].cities[1].buildings[41]==0)'),
      ('expiration and cooldown boundaries','Prince.Activate(0,"possess",1,target.id);GameEvents.PlayerDoTurn(0);assert(Prince.State(0).kind);turn=1;GameEvents.PlayerDoTurn(0);assert(not Prince.State(0).kind and Prince.State(0).readyTurn==8 and Prince.Body(0).moves==120);turn=8;assert(Prince.Ready(0))'),
      ('borrowed death ends technique without killing Trent','Prince.Activate(0,"swap",1,target.id);Prince.Borrowed(0):Kill(false,1);Flush();assert(not Prince.State(0).kind and Prince.Body(0).owner==0 and Prince.State(0).fallen~=1)'),
      ('normal death removes entire empire before first city','Players[0].cities={};Prince.Body(0):Kill(false,1);assert(Prince.State(0).fallen==1);Flush();assert(Count(0)==0 and #Players[0].cities==0)'),
      ('original death during possession removes entire empire','Prince.Activate(0,"possess",1,target.id);Prince.Body(0):Kill(false,1);Flush();assert(Prince.State(0).fallen==1 and Count(0)==0 and #Players[0].cities==0 and Count(1)==1)'),
      ('original enemy-controlled death during swap removes entire empire','Prince.Activate(0,"swap",1,target.id);Prince.Body(0):Kill(false,2);Flush();assert(Prince.State(0).fallen==1 and Count(0)==0 and #Players[0].cities==0)'),
      ('normal upgrades preserve permanent identity and state','local s=Prince.State(0);s.possession=9;s.swap=6;s.readyTurn=7;for i=1,3 do local old=Prince.Body(0);local new=Players[0]:InitUnit(13,0,0);GameEvents.UnitUpgraded(0,old.id,new.id,false);new:Convert(old,true);assert(Prince.Body(0).id==new.id and s.fallen~=1) end;assert(s.possession==9 and s.swap==6 and s.readyTurn==7);turn=7;Prince.Body(0):SetMoves(120);assert(Prince.Activate(0,"possess",1,target.id))'),
      ('death after multiple upgrades','for i=1,3 do local old=Prince.Body(0);local new=Players[0]:InitUnit(13,0,0);GameEvents.UnitUpgraded(0,old.id,new.id,false);new:Convert(old,true) end;Prince.Body(0):Kill(false,1);Flush();assert(Prince.State(0).fallen==1 and Count(0)==0)'),
      ('save normalizes and resumes possession without progression','Prince.Activate(0,"possess",1,target.id);local s=Prince.State(0);GameEvents.GameSave();assert(s.suspended==1 and Count(0)==1 and Count(1)==1);Flush();assert(not s.suspended and Count(0)==2 and s.possession==1 and s.readyTurn==8)'),
      ('save normalizes and resumes swap without healing','Prince.Activate(0,"swap",1,target.id);Prince.Body(0).damage=25;Prince.Borrowed(0).damage=43;GameEvents.GameSave();assert(Prince.Body(0).owner==0 and Prince.Borrowed(0).owner==1);Flush();assert(Prince.Body(0).owner==1 and Prince.Body(0).damage==25 and Prince.Borrowed(0).damage==43 and Count(0)==1 and Count(1)==1)'),
      ('load reconstructs state and active swap','Prince.Activate(0,"swap",1,target.id);Prince.Suspend(0);local old=Prince;Prince.states={};local s=Prince.State(0);Prince.Reindex();Prince.Resume(0);assert(s.kind=="swap" and s.swap==1 and s.possession==0 and Prince.Body(0).owner==1 and Count(0)==1 and Count(1)==1)'),
      ('eliminated target owner does not resurrect','Prince.Activate(0,"possess",1,target.id);Players[1].alive=false;Prince.End(0);assert(Count(0)==1 and Count(1)==0 and not Prince.State(0).kind)'),
      ('peace returns both bodies and leaves cooldown','Prince.Activate(0,"swap",1,target.id);Teams[0].war=false;GameEvents.MakePeace(0,1,true);assert(not Prince.State(0).kind and Prince.Body(0).owner==0 and Prince.State(0).readyTurn==8)'),
      ('failed target allocation grants no mastery or cooldown','failOwner=0;assert(not Prince.Activate(0,"possess",1,target.id));assert(Prince.State(0).possession==0 and Prince.State(0).readyTurn==0 and Count(1)==1)'),
      ('failed swap allocation leaves both sources intact','failOwner=1;assert(not Prince.Activate(0,"swap",1,target.id));assert(Prince.State(0).swap==0 and Count(0)==1 and Count(1)==1 and Prince.Body(0).owner==0)'),
      ('AI uses authoritative backend against local targets','Players[0].human=false;Prince.AI(0);assert(Prince.State(0).kind and Prince.State(0).possession+Prince.State(0).swap==1)'),
      ('AI retreats when endangered','Players[0].human=false;Prince.Body(0).damage=70;Prince.AI(0);assert(not Prince.State(0).kind and Prince.Body(0).moves==0)'),
      ('unexpected borrowed conversion follows identity and cancels safely','Prince.Activate(0,"possess",1,target.id);local old=Prince.Borrowed(0);local converted=Players[2]:InitUnit(12,1,0);converted:Convert(old,false);Flush();assert(not Prince.State(0).kind and Count(1)==1 and Count(0)==1)'),
    ]
    for name,code in scenarios:scenario(name,code)
    lua=runtime()
    lua.execute(r'''
     for speedIndex,expected in pairs({[0]={8,3},[1]={5,2},[2]={12,5},[3]={24,9},[4]={16,6}})do
      for stacks=0,12 do for _,kind in ipairs({'possess','swap'})do
       local v=Prince.Rules.Values(kind,stacks,GameInfo.GameSpeeds[speedIndex])
       assert(v.cooldown==expected[1]);assert(v.level==math.min(5,math.floor(stacks/3)+1))
       if stacks==12 then assert(v.duration==expected[2])end
      end end
     end
     for i=0,25 do assert(Prince.Rules.Gain(i)<=12)end
     for level,stacks in ipairs({0,3,6,9,12})do
      local p=Prince.Rules.Values('possess',stacks,GameInfo.GameSpeeds[0])
      local s=Prince.Rules.Values('swap',stacks,GameInfo.GameSpeeds[0])
      assert(p.damage==({-35,-20,-10,0,10})[level]);assert(s.damage==({-20,0,15,25,40})[level])
      assert(s.resistance==({80,82,85,88,90})[level]);assert(p.duration==({1,1,2,2,3})[level])
     end
    ''')
    print('PASS: all 130 speed/mastery combinations, thresholds and permanent cap')
    lua=runtime()
    lua.execute(r'''
      function Control()
       return {hidden=false,callbacks={},SetHide=function(self,v)self.hidden=v end,
        IsHidden=function(self)return self.hidden end,SetText=function(self,v)self.text=v end,
        SetDisabled=function(self,v)self.disabled=v end,SetToolTipString=function()end,
        ChangeParent=function()end,RegisterCallback=function(self,k,f)self.callbacks[k]=f end,
        CalculateSize=function()end,ReprocessAnchoring=function()end,CalculateInternalSize=function()end}
      end
      function ControlsTable()return setmetatable({},{__index=function(t,k)local c=Control();t[k]=c;return c end})end
      Controls=ControlsTable();Controls.Panel.hidden=true
      uiItems={}
      InstanceManager={new=function()return {
       ResetInstances=function()uiItems={}end,
       GetInstance=function()local c=ControlsTable();uiItems[#uiItems+1]=c;return c end}end}
      ContextPtr={LookUpControl=function()return {}end,SetInputHandler=function()end}
      UI={GetHeadSelectedUnit=function()return Prince.Body(0)end}
      Mouse={eLClick=1};KeyEvents={KeyDown=1};Keys={VK_ESCAPE=27}
      SystemUpdateUIType={BulkHideUI=1,BulkShowUI=2}
      IconHookup=function()end;Vector2=function(x,y)return {x=x,y=y}end
      Vector4=function()return {}end;ToHexFromGrid=function(v)return v end
      include=function()end
    ''')
    lua.execute((ROOT/'Princedom/UI/PrincePanel.lua').read_text(encoding='utf-8'))
    lua.execute(r'''
      assert(not Controls.Open.hidden)
      Controls.Open.callbacks[1]();Controls.Possess.callbacks[1]()
      assert(not Controls.Panel.hidden and #uiItems==2)
      Events.SerialEventEnterCityScreen();assert(Controls.Open.hidden and Controls.Panel.hidden)
      Events.SerialEventExitCityScreen();assert(not Controls.Open.hidden)
      Events.AILeaderMessage();assert(Controls.Open.hidden)
      Events.LeavingLeaderViewMode();assert(not Controls.Open.hidden)
      Events.SerialEventGameMessagePopupShown();assert(Controls.Open.hidden)
      Events.SerialEventGameMessagePopupProcessed();assert(not Controls.Open.hidden)
      Events.SystemUpdateUI(1);assert(Controls.Open.hidden)
      Events.SystemUpdateUI(2);assert(not Controls.Open.hidden)
      Controls.Open.callbacks[1]();Controls.Possess.callbacks[1]();uiItems[1].TargetButton.callbacks[1]()
      assert(Prince.State(0).kind=='possess' and Controls.Panel.hidden)
    ''')
    print('PASS: event-driven panel, target callback and city/diplomacy/popup/bulk visibility')
    print(f'Princedom passed: {len(scenarios)+2} scenarios; real in-game tests remain manual')


if __name__=='__main__':run()
