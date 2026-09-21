"""Exercise Freehold possession transactions and audit cross-system safety guards."""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / ".modbuddy/test-deps"))
from lupa.lua51 import LuaRuntime


MOCK = r'''
save, nextID, deferredRestore, alerts, acquireMode = {}, 100, nil, {}, 'success'
local rawTypes={
 CIVILIZATION_UNA_COURT=1,UNIT_UNA_TRENTROULS=10,UNIT_DOMINION_TRENTROULS=11,
 UNIT_UNA_BUDDY=12,PROMOTION_UNA_POSSESSED=20,PROMOTION_UNA_POSSESSION_READY=21,
 PROMOTION_UNA_POSSESSION_COOLDOWN=22,CIVILIZATION_DOMINION_UNA_COURT=4,
 CIVILIZATION_ULTIMATE_POSSESSION=5,UNIT_WARRIOR=13,UNIT_ULTIMATE_GOLDEN_RETRIEVER=14,
 PROMOTION_DOMINION_BORROWED_BODY=23,PROMOTION_DOMINION_ENEMY_IN_TRENT=24,
 PROMOTION_DOMINION_SWAP_READY=25,PROMOTION_DOMINION_SWAP_COOLDOWN=26,
 PROMOTION_DOMINION_SWAP_IMMUNE=27,PROMOTION_ULTIMATE_POSSESSED=28,DOMAIN_AIR=2}
GameInfoTypes=setmetatable(rawTypes,{__index=function()return nil end})
GameDefines={MAX_MAJOR_CIVS=3,MAX_PLAYERS=3,MOVE_DENOMINATOR=60}
Game={GetGameSpeedType=function()return 0 end,GetElapsedGameTurns=function()return 1 end}
GameInfo={
 GameSpeeds={[0]={Type='GAMESPEED_STANDARD'}},
 Units=setmetatable({[10]={Type='UNIT_UNA_TRENTROULS',Trade=0},[11]={Type='UNIT_DOMINION_TRENTROULS',Trade=0},
  [30]={Type='UNIT_TEST_TARGET',Trade=0,NukeDamageLevel=0,Suicide=0,Cost=80,WorkRate=0},
  [31]={Type='UNIT_TEST_GREAT_PERSON',Trade=0,Special='SPECIALUNIT_PEOPLE'},
  [32]={Type='UNIT_TEST_RELIGIOUS',Trade=0,ReligionSpreads=2,ReligiousStrength=100},
  [33]={Type='UNIT_TEST_WORKER',Trade=0,WorkRate=100},[34]={Type='UNIT_TEST_SETTLER',Trade=0,Found=1}},
  {__index=function(_,key)return {Type='UNIT_'..tostring(key),Trade=0,NukeDamageLevel=0,Suicide=0}end}),
 UnitPromotions=function()return Iter({{ID=40},{ID=41}})end,
 Unit_ResourceQuantityRequirements=function()return Iter({})end}
Modding={OpenSaveData=function()return {
 GetValue=function(key)return save[key]end,
 SetValue=function(key,value)save[key]=value end}end}
function Event()
 local event={callbacks={}}
 event.Add=function(callback)event.callbacks[#event.callbacks+1]=callback end
 return setmetatable(event,{__call=function(self,...)
  local result=true
  for _,callback in ipairs(self.callbacks)do
   local value=callback(...)
   if value==false then result=false end
  end
  return result
 end})
end
function EventsTable()return setmetatable({},{__index=function(t,key)local e=Event();rawset(t,key,e);return e end})end
GameEvents,LuaEvents=EventsTable(),EventsTable()
Events={GameplayAlertMessage=function(message)alerts[#alerts+1]=message end}
NotificationTypes={NOTIFICATION_GENERIC=1}
CommandTypes={COMMAND_DELETE=1,COMMAND_UPGRADE=2,COMMAND_GIFT=3}
Map={cityPlots={},PlotDistance=function()return 1 end,PlotXYWithRangeCheck=function()return nil end}
function Iter(items)local index=0;return function()index=index+1;return items[index]end end
function Plot(x,y)
 local plot={x=x,y=y}
 function plot:GetX()return self.x end
 function plot:GetY()return self.y end
 function plot:IsCity()return false end
 return plot
end
function Map.GetPlot(x,y)
 local plot=Plot(x,y)
 function plot:GetPlotCity()return Map.cityPlots[tostring(x)..':'..tostring(y)]end
 function plot:IsCity()return self:GetPlotCity()~=nil end
 return plot
end
function City(owner,id,x,y)
 local city={owner=owner,id=id,x=x,y=y,dead=false,buildings={}}
 function city:GetOwner()return self.owner end
 function city:GetID()return self.id end
 function city:GetX()return self.x end
 function city:GetY()return self.y end
 function city:GetNumRealBuilding(kind)return self.buildings[kind] or 0 end
 function city:SetNumRealBuilding(kind,value)self.buildings[kind]=value end
 function city:Kill()
  if self.dead then return end
  self.dead=true
  local cities=Players[self.owner].cities
  for index,candidate in ipairs(cities)do if candidate==self then table.remove(cities,index)break end end
  Map.cityPlots[tostring(self.x)..':'..tostring(self.y)]=nil
 end
 Map.cityPlots[tostring(x)..':'..tostring(y)]=city
 return city
end
function Unit(owner,id,kind,x,y)
 local unit={owner=owner,id=id,kind=kind,x=x,y=y,dead=false,damage=27,experience=44,level=5,
  moves=37,direction=3,embarked=true,fortify=4,name='Veteran',promotions={[40]=true},
  scriptData='script-'..tostring(id),cargo=false,cargoCount=0}
 function unit:GetOwner()return self.owner end
 function unit:GetID()return self.id end
 function unit:GetUnitType()return self.kind end
 function unit:GetUnitAIType()return 1 end
 function unit:GetX()return self.x end
 function unit:GetY()return self.y end
 function unit:GetPlot()return Plot(self.x,self.y)end
 function unit:IsDead()return self.dead end
 function unit:IsDelayedDeath()return self.dead end
 function unit:GetDomainType()return 0 end
 function unit:IsCargo()return self.cargo end
 function unit:GetCargo()return self.cargoCount end
 function unit:IsCombatUnit()return true end
 function unit:GetDamage()return self.damage end
 function unit:SetDamage(value)self.damage=value end
 function unit:GetExperience()return self.experience end
 function unit:SetExperience(value)self.experience=value end
 function unit:ChangeExperience(value)self.experience=self.experience+value end
 function unit:GetLevel()return self.level end
 function unit:SetLevel(value)self.level=value end
 function unit:GetMoves()return self.moves end
 function unit:SetMoves(value)self.moves=value end
 function unit:GetFacingDirection()return self.direction end
 function unit:IsEmbarked()return self.embarked end
 function unit:SetEmbarked(value)self.embarked=value end
 function unit:GetFortifyTurns()return self.fortify end
 function unit:SetFortifyTurns(value)self.fortify=value end
 function unit:HasName()return true end
 function unit:GetNameNoDesc()return self.name end
 function unit:GetName()return self.name end
 function unit:SetName(value)self.name=value end
 function unit:GetScriptData()return self.scriptData end
 function unit:SetScriptData(value)self.scriptData=value end
 function unit:IsHasPromotion(id)return self.promotions[id] or false end
 function unit:SetHasPromotion(id,value)self.promotions[id]=value end
 function unit:JumpToNearestValidPlot()self.jumped=true return true end
 function unit:GetBaseCombatStrength()return 20 end
 function unit:GetBaseRangedCombatStrength()return 0 end
 function unit:Kill(_,killer)
  if self.dead then return end
  GameEvents.UnitPrekill(self.owner,self.id,self.kind,self.x,self.y,false,killer)
  self.dead=true
  local player=Players[self.owner]
  for index,candidate in ipairs(player.units)do
   if candidate==self then table.remove(player.units,index)break end
  end
 end
 return unit
end
function Player(id,civ)
 local player={id=id,civ=civ,alive=true,human=id==0,barbarian=false,units={},cities={},initFailures=0,era=0,goldenAge=0}
 function player:GetID()return self.id end
 function player:IsAlive()return self.alive end
 function player:IsHuman()return self.human end
 function player:IsBarbarian()return self.barbarian end
 function player:GetCivilizationType()return self.civ end
 function player:GetTeam()return self.id end
 function player:GetCurrentEra()return self.era end
 function player:GetNumResourceAvailable()return 99 end
 function player:ChangeGoldenAgeProgressMeter(value)self.goldenAge=self.goldenAge+value end
 function player:Units()return Iter(self.units)end
 function player:Cities()return Iter(self.cities)end
 function player:GetCapitalCity()for _,city in ipairs(self.cities)do if not city.dead then return city end end end
 function player:GetCityByID(id)for _,city in ipairs(self.cities)do if city.id==id and not city.dead then return city end end end
 function player:GetStartingPlot()return Plot(0,0)end
 function player:GetEndTurnBlockingType()return -1 end
 function player:GetUnitByID(id)for _,unit in ipairs(self.units)do if unit.id==id then return unit end end end
 function player:InitUnit(kind,x,y,ai,direction)
  if self.initFailures>0 then self.initFailures=self.initFailures-1 return nil end
  nextID=nextID+1
  local unit=Unit(self.id,nextID,kind,x,y)
  unit.damage,unit.experience,unit.level,unit.moves=0,0,1,120
  unit.direction,unit.embarked,unit.fortify=direction or 0,false,0
  unit.name,unit.promotions='',{}
  self.units[#self.units+1]=unit
  return unit
 end
 function player:AddNotification()end
 function player:AcquireCity(city)
  if acquireMode=='throw' then error('simulated AcquireCity failure')end
  if acquireMode=='noop' then return end
  local oldCities=Players[city.owner].cities
  for index,candidate in ipairs(oldCities)do if candidate==city then table.remove(oldCities,index)break end end
  city.owner=self.id;self.cities[#self.cities+1]=city
 end
 return player
end
Players={}
Teams={
 [0]={IsAtWar=function(_,other)return other==1 or other==2 end},
 [1]={IsAtWar=function(_,other)return other==0 end},
 [2]={IsAtWar=function(_,other)return other==0 end}}
function ResetWorld()
 save,nextID,deferredRestore,alerts,acquireMode={},100,nil,{},'success';Map.cityPlots={}
 Players[0],Players[1],Players[2]=Player(0,1),Player(1,99),Player(2,98)
 local trent=Unit(0,10,10,0,0);trent.embarked=false;Players[0].units={trent}
 local target=Unit(1,20,30,1,0);Players[1].units={target}
end
function UnaCourt_FindTrentrouls(player)
 for unit in player:Units()do if unit:GetUnitType()==10 then return unit end end
end
function UnaCourt_QueueDeferredRestore(callback)deferredRestore=callback return true end
ResetWorld()
'''


def new_runtime():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    lua.execute((ROOT / "Lua/UnaCourtPossession.lua").read_text(encoding="utf-8"))
    return lua


lua = new_runtime()


def scenario(name, code):
    lua.execute("ResetWorld()")
    lua.execute(code)
    print("PASS", name)


scenario(
    "failed activation recreates the original unit instead of losing it",
    "Players[0].initFailures=1;assert(not UnaCourt_StartPossession(0,10,1,20));"
    "assert(not UnaCourt_GetPossessionStatus(0).active);assert(#Players[1].units==1);"
    "local unit=Players[1].units[1];assert(unit.kind==30 and unit.damage==27 and unit.experience==44 and unit.level==5)",
)

scenario(
    "transfer preserves standard state and blocks unsafe ownership commands",
    "assert(UnaCourt_StartPossession(0,10,1,20));local status=UnaCourt_GetPossessionStatus(0);"
    "local unit=Players[0]:GetUnitByID(status.unitID);"
    "assert(unit and unit.damage==27 and unit.experience==44 and unit.level==5 and unit.moves==37);"
    "assert(unit.direction==3 and unit.embarked and unit.fortify==4 and unit.promotions[40]);"
    "assert(unit.scriptData=='script-20');"
    "assert(GameEvents.PlayerCanGiftUnit(0,1,unit.id)==false);"
    "assert(GameEvents.PlayerCanDoCommand(0,unit.id,CommandTypes.COMMAND_DELETE)==false);"
    "assert(GameEvents.PlayerCanDoCommand(0,unit.id,CommandTypes.COMMAND_UPGRADE)==false);"
    "assert(GameEvents.CanHaveAnyUpgrade(0,unit.id)==false)",
)

scenario(
    "return preserves ScriptData changes made while possessed",
    "assert(UnaCourt_StartPossession(0,10,1,20));local status=UnaCourt_GetPossessionStatus(0);"
    "Players[0]:GetUnitByID(status.unitID):SetScriptData('changed-while-possessed');"
    "local ended,returnedID=UnaCourt_EndPossession(0,'test');assert(ended);"
    "assert(Players[1]:GetUnitByID(returnedID):GetScriptData()=='changed-while-possessed')",
)

scenario(
    "unsafe stateful targets are excluded while Workers and Settlers remain eligible",
    "local trent=Players[0]:GetUnitByID(10);local target=Players[1]:GetUnitByID(20);"
    "target.kind=31;assert(not UnaCourt_IsEligiblePossessionTarget(0,trent,target));"
    "target.kind=32;assert(not UnaCourt_IsEligiblePossessionTarget(0,trent,target));"
    "target.kind=30;target.cargo=true;assert(not UnaCourt_IsEligiblePossessionTarget(0,trent,target));"
    "target.cargo=false;target.cargoCount=1;assert(not UnaCourt_IsEligiblePossessionTarget(0,trent,target));"
    "target.cargoCount=0;target.kind=33;assert(UnaCourt_IsEligiblePossessionTarget(0,trent,target));"
    "target.kind=34;assert(UnaCourt_IsEligiblePossessionTarget(0,trent,target))",
)

scenario(
    "activation aborts when the original unit remains live after Kill",
    "local target=Players[1]:GetUnitByID(20);target.Kill=function()end;"
    "assert(not UnaCourt_StartPossession(0,10,1,20));"
    "assert(#Players[1].units==1 and #Players[0].units==1 and not UnaCourt_GetPossessionStatus(0).active)",
)

scenario(
    "failed return rolls the body back under the possessor with a fresh tracked ID",
    "assert(UnaCourt_StartPossession(0,10,1,20));local old=UnaCourt_GetPossessionStatus(0).unitID;"
    "Players[1].initFailures=1;assert(not UnaCourt_EndPossession(0,'test'));"
    "local status=UnaCourt_GetPossessionStatus(0);assert(status.active and status.unitID~=old);"
    "local unit=Players[0]:GetUnitByID(status.unitID);assert(unit and unit.promotions[20])",
)

scenario(
    "a transfer exception resets suppression and retains the untouched body",
    "assert(UnaCourt_StartPossession(0,10,1,20));local status=UnaCourt_GetPossessionStatus(0);"
    "local unit=Players[0]:GetUnitByID(status.unitID);local kill=unit.Kill;"
    "unit.Kill=function()error('simulated transfer failure')end;"
    "assert(not UnaCourt_EndPossession(0,'test'));assert(UnaCourt_GetPossessionStatus(0).active);"
    "unit.Kill=kill;unit:Kill(false,-1);assert(not UnaCourt_GetPossessionStatus(0).active)",
)

scenario(
    "save normalization updates IDs and restores the active possession",
    "assert(UnaCourt_StartPossession(0,10,1,20));local before=UnaCourt_GetPossessionStatus(0).unitID;"
    "GameEvents.GameSave();assert(not UnaCourt_GetPossessionStatus(0).active);assert(deferredRestore);"
    "deferredRestore();local status=UnaCourt_GetPossessionStatus(0);assert(status.active and status.unitID~=before);"
    "local unit=Players[0]:GetUnitByID(status.unitID);"
    "assert(unit and unit.damage==27 and unit.level==5 and unit.scriptData=='script-20')",
)

scenario(
    "capture clears possession without recreating a consumed body",
    "assert(UnaCourt_StartPossession(0,10,1,20));local status=UnaCourt_GetPossessionStatus(0);"
    "local unit=Players[0]:GetUnitByID(status.unitID);local state={kind=unit.kind,damage=unit.damage};"
    "unit:Kill(false,2);Players[2].units={Unit(2,30,state.kind,unit.x,unit.y)};"
    "assert(not UnaCourt_GetPossessionStatus(0).active);assert(#Players[0].units==1);"
    "assert(#Players[1].units==0 and #Players[2].units==1)",
)

scenario(
    "deliberate expenditure clears possession without restoring the unit",
    "assert(UnaCourt_StartPossession(0,10,1,20));local status=UnaCourt_GetPossessionStatus(0);"
    "Players[0]:GetUnitByID(status.unitID):Kill(false,-1);"
    "assert(not UnaCourt_GetPossessionStatus(0).active);assert(#Players[0].units==1);"
    "GameEvents.GameSave();assert(deferredRestore==nil and #Players[1].units==0)",
)


def specialized_runtime(relative, setup):
    runtime = LuaRuntime(unpack_returned_tuples=True)
    runtime.execute(MOCK)
    runtime.execute(setup)
    runtime.execute((ROOT / relative).read_text(encoding="utf-8"))
    return runtime


ultimate = specialized_runtime(
    "Lua/UltimatePossession.lua",
    r'''
function ResetUltimateWorld()
 ResetWorld();Players[0].civ=5;Players[0].era=1
 Players[2].units={Unit(2,21,30,2,0)}
end
ResetUltimateWorld()
''',
)


def ultimate_scenario(name, code):
    ultimate.execute("ResetUltimateWorld()")
    ultimate.execute(code)
    print("PASS", name)


ultimate_scenario(
    "mass possession rejects duplicate table targets",
    "assert(not Ultimate_StartPossession(0,{{ownerID=1,unitID=20},{ownerID=1,unitID=20}}));"
    "assert(#Players[1].units==1 and save['ULTIMATE_POSSESSION_0_ACTIVE']~=1)",
)

ultimate_scenario(
    "mass possession excludes unsafe stateful and cargo targets",
    "local target=Players[1]:GetUnitByID(20);target.kind=31;assert(not Ultimate_IsEligibleTarget(0,target));"
    "target.kind=32;assert(not Ultimate_IsEligibleTarget(0,target));"
    "target.kind=30;target.cargo=true;assert(not Ultimate_IsEligibleTarget(0,target));"
    "target.cargo=false;target.cargoCount=1;assert(not Ultimate_IsEligibleTarget(0,target));"
    "target.cargoCount=0;target.kind=33;assert(Ultimate_IsEligibleTarget(0,target));"
    "target.kind=34;assert(Ultimate_IsEligibleTarget(0,target))",
)

ultimate_scenario(
    "mass activation aborts when Kill leaves the original unit live",
    "local target=Players[1]:GetUnitByID(20);target.Kill=function()end;"
    "assert(not Ultimate_StartPossession(0,{{ownerID=1,unitID=20}}));"
    "assert(#Players[1].units==1 and #Players[0].units==1)",
)

ultimate_scenario(
    "mass possession preserves state and rolls a failed return back",
    "assert(Ultimate_StartPossession(0,{{ownerID=1,unitID=20}}));"
    "local old=save['ULTIMATE_POSSESSION_0_SLOT_1_UNIT_ID'];local unit=Players[0]:GetUnitByID(old);"
    "assert(unit and unit.damage==27 and unit.experience==44 and unit.level==5 and unit.embarked);"
    "assert(unit.scriptData=='script-20');"
    "Players[1].initFailures=1;assert(not Ultimate_EndPossession(0,'test',false));"
    "local fresh=save['ULTIMATE_POSSESSION_0_SLOT_1_UNIT_ID'];"
    "assert(save['ULTIMATE_POSSESSION_0_ACTIVE']==1 and fresh~=old and Players[0]:GetUnitByID(fresh))",
)

ultimate_scenario(
    "partial mass save normalization rolls earlier slots back",
    "assert(Ultimate_StartPossession(0,{{ownerID=1,unitID=20},{ownerID=2,unitID=21}}));"
    "Players[2].initFailures=1;GameEvents.GameSave();"
    "assert(save['ULTIMATE_POSSESSION_0_ACTIVE']==1 and deferredRestore==nil);"
    "local id1=save['ULTIMATE_POSSESSION_0_SLOT_1_UNIT_ID'];"
    "local id2=save['ULTIMATE_POSSESSION_0_SLOT_2_UNIT_ID'];"
    "assert(Players[0]:GetUnitByID(id1)~=nil,'missing slot 1 '..tostring(id1).."
    "' p0='..tostring(#Players[0].units)..' p1='..tostring(#Players[1].units).."
    "' p1id='..tostring(#Players[1].units>0 and Players[1].units[1].id or -1));"
    "assert(Players[0]:GetUnitByID(id2)~=nil,'missing slot 2 '..tostring(id2));"
    "assert(#Players[1].units==0 and #Players[2].units==0)",
)

ultimate_scenario(
    "mass possession save normalization restores fresh tracked IDs",
    "assert(Ultimate_StartPossession(0,{{ownerID=1,unitID=20},{ownerID=2,unitID=21}}));"
    "local old1=save['ULTIMATE_POSSESSION_0_SLOT_1_UNIT_ID'];"
    "local old2=save['ULTIMATE_POSSESSION_0_SLOT_2_UNIT_ID'];GameEvents.GameSave();"
    "assert(save['ULTIMATE_POSSESSION_0_ACTIVE']==0 and deferredRestore);deferredRestore();"
    "local new1=save['ULTIMATE_POSSESSION_0_SLOT_1_UNIT_ID'];"
    "local new2=save['ULTIMATE_POSSESSION_0_SLOT_2_UNIT_ID'];"
    "assert(save['ULTIMATE_POSSESSION_0_ACTIVE']==1 and new1~=old1 and new2~=old2);"
    "assert(Players[0]:GetUnitByID(new1):GetScriptData()=='script-20');"
    "assert(Players[0]:GetUnitByID(new2):GetScriptData()=='script-21')",
)


dominion = specialized_runtime(
    "Lua/DominionBodySwap.lua",
    r'''
function ResetDominionWorld()
 ResetWorld();Players[0].civ=4;Players[0].units={Unit(0,10,11,0,0)}
end
function Dominion_FindOwnedTrent(player)
 for unit in player:Units()do if unit:GetUnitType()==11 then return unit end end
end
function Dominion_RefreshPlayer()end
ResetDominionWorld()
''',
)


def dominion_scenario(name, code):
    dominion.execute("ResetDominionWorld()")
    dominion.execute(code)
    print("PASS", name)


dominion_scenario(
    "body swap rolls failed two-body returns back with fresh IDs",
    "assert(Dominion_StartBodySwap(0,10,1,20));"
    "local oldBorrowed=save['DOMINION_SWAP_0_BORROWED_ID'];"
    "local oldTrent=save['DOMINION_SWAP_0_TRENT_UNIT_ID'];"
    "Players[1].initFailures=1;assert(not Dominion_EndBodySwap(0,'test',true,false,false));"
    "local newBorrowed=save['DOMINION_SWAP_0_BORROWED_ID'];"
    "local newTrent=save['DOMINION_SWAP_0_TRENT_UNIT_ID'];"
    "assert(save['DOMINION_SWAP_0_ACTIVE']==1 and newBorrowed~=oldBorrowed and newTrent~=oldTrent);"
    "assert(Players[0]:GetUnitByID(newBorrowed):GetScriptData()=='script-20');"
    "assert(Players[1]:GetUnitByID(newTrent):GetScriptData()=='script-10');"
    "assert(Dominion_EndBodySwap(0,'retry',true,false,false));"
    "assert(save['DOMINION_SWAP_0_ACTIVE']==0 and Dominion_FindOwnedTrent(Players[0]))",
)

dominion_scenario(
    "body swap excludes unsafe stateful and cargo targets",
    "local trent=Players[0]:GetUnitByID(10);local target=Players[1]:GetUnitByID(20);"
    "target.kind=31;assert(not Dominion_IsEligibleBodySwapTarget(0,trent,target));"
    "target.kind=32;assert(not Dominion_IsEligibleBodySwapTarget(0,trent,target));"
    "target.kind=30;target.cargo=true;assert(not Dominion_IsEligibleBodySwapTarget(0,trent,target));"
    "target.cargo=false;target.cargoCount=1;assert(not Dominion_IsEligibleBodySwapTarget(0,trent,target));"
    "target.cargoCount=0;target.kind=33;assert(Dominion_IsEligibleBodySwapTarget(0,trent,target));"
    "target.kind=34;assert(Dominion_IsEligibleBodySwapTarget(0,trent,target))",
)

dominion_scenario(
    "body swap activation aborts when Kill leaves the target live",
    "local target=Players[1]:GetUnitByID(20);target.Kill=function()end;"
    "assert(not Dominion_StartBodySwap(0,10,1,20));"
    "assert(#Players[0].units==1 and #Players[1].units==1)",
)

dominion_scenario(
    "body swap save normalization restores both fresh tracked IDs",
    "assert(Dominion_StartBodySwap(0,10,1,20));"
    "local oldBorrowed=save['DOMINION_SWAP_0_BORROWED_ID'];"
    "local oldTrent=save['DOMINION_SWAP_0_TRENT_UNIT_ID'];GameEvents.GameSave();"
    "assert(save['DOMINION_SWAP_0_ACTIVE']==0 and deferredRestore);deferredRestore();"
    "local newBorrowed=save['DOMINION_SWAP_0_BORROWED_ID'];"
    "local newTrent=save['DOMINION_SWAP_0_TRENT_UNIT_ID'];"
    "assert(save['DOMINION_SWAP_0_ACTIVE']==1 and newBorrowed~=oldBorrowed and newTrent~=oldTrent);"
    "assert(Players[0]:GetUnitByID(newBorrowed):GetScriptData()=='script-20');"
    "assert(Players[1]:GetUnitByID(newTrent):GetScriptData()=='script-10')",
)

dominion_scenario(
    "captured borrowed body clears the swap without duplicating its original",
    "assert(Dominion_StartBodySwap(0,10,1,20));"
    "local borrowed=Players[0]:GetUnitByID(save['DOMINION_SWAP_0_BORROWED_ID']);"
    "borrowed:Kill(false,2);Players[2].units={Unit(2,30,30,borrowed.x,borrowed.y)};"
    "Dominion_ProcessPendingReturns(true);assert(save['DOMINION_SWAP_0_ACTIVE']==0);"
    "assert(Dominion_FindOwnedTrent(Players[0]) and #Players[1].units==0 and #Players[2].units==1)",
)


def freehold_collapse_scenario(name, code):
    runtime = LuaRuntime(unpack_returned_tuples=True)
    runtime.execute(MOCK)
    runtime.execute((ROOT / "Lua/UnaCourtPossession.lua").read_text(encoding="utf-8"))
    runtime.execute((ROOT / "Lua/UnaCourtCore.lua").read_text(encoding="utf-8"))
    runtime.execute(
        "function ResetFreeholdCollapse(mode) ResetWorld();acquireMode=mode;"
        "local city=City(0,1,5,5);Players[0].cities={city} end"
    )
    runtime.execute(code)
    print("PASS", name)


for mode, setup, expectation in (
    ("success", "", "assert(city and city:GetOwner()==1)"),
    ("throw", "", "assert(city==nil)"),
    ("noop", "", "assert(city==nil)"),
    ("success", "killer=-1", "assert(city==nil)"),
    ("success", "Players[1].barbarian=true", "assert(city==nil)"),
    ("success", "Players[1].alive=false", "assert(city==nil)"),
):
    setup_code = f"{setup};" if setup else ""
    freehold_collapse_scenario(
        f"Freehold collapse capital resolution: {mode} {setup or 'valid killer'}",
        f"ResetFreeholdCollapse('{mode}');local killer=1;{setup_code}"
        "Players[0]:GetUnitByID(10):Kill(false,killer);GameEvents.PlayerDoTurn(2);"
        "local city=Map.GetPlot(5,5):GetPlotCity();" + expectation,
    )


freehold_collapse_scenario(
    "Freehold collapse retries a transient possessed-body return failure",
    "ResetFreeholdCollapse('success');assert(UnaCourt_StartPossession(0,10,1,20));"
    "Players[1].initFailures=1;Players[0]:GetUnitByID(10):Kill(false,1);"
    "GameEvents.PlayerDoTurn(2);assert(not UnaCourt_GetPossessionStatus(0).active);"
    "assert(#Players[1].units==1 and Players[1].units[1].kind==30);"
    "assert(Players[1].units[1].scriptData=='script-20');"
    "assert(Map.GetPlot(5,5):GetPlotCity():GetOwner()==1)",
)

freehold_collapse_scenario(
    "Freehold collapse handles a consumed borrowed body",
    "ResetFreeholdCollapse('noop');assert(UnaCourt_StartPossession(0,10,1,20));"
    "local body=Players[0]:GetUnitByID(UnaCourt_GetPossessionStatus(0).unitID);body:Kill(false,-1);"
    "Players[0]:GetUnitByID(10):Kill(false,-1);GameEvents.PlayerDoTurn(2);"
    "assert(not UnaCourt_GetPossessionStatus(0).active and #Players[1].units==0)",
)

freehold_collapse_scenario(
    "Freehold collapse handles an eliminated original owner",
    "ResetFreeholdCollapse('noop');assert(UnaCourt_StartPossession(0,10,1,20));"
    "Players[1].alive=false;Players[0]:GetUnitByID(10):Kill(false,-1);GameEvents.PlayerDoTurn(2);"
    "assert(not UnaCourt_GetPossessionStatus(0).active and #Players[0].units==0)",
)


def dominion_collapse_scenario(name, code):
    runtime = LuaRuntime(unpack_returned_tuples=True)
    runtime.execute(MOCK)
    runtime.execute("Players[0].civ=4;Players[0].units={Unit(0,10,11,0,0)}")
    runtime.execute((ROOT / "Lua/DominionCore.lua").read_text(encoding="utf-8"))
    runtime.execute((ROOT / "Lua/DominionBodySwap.lua").read_text(encoding="utf-8"))
    runtime.execute(
        "function ResetDominionCollapse(mode) ResetWorld();acquireMode=mode;Players[0].civ=4;"
        "Players[0].units={Unit(0,10,11,0,0)};local city=City(0,1,5,5);Players[0].cities={city} end"
    )
    runtime.execute(code)
    print("PASS", name)


dominion_collapse_scenario(
    "Dominion collapse retries a transient return without killing death-path Trent twice",
    "ResetDominionCollapse('success');assert(Dominion_StartBodySwap(0,10,1,20));"
    "Players[1].initFailures=1;local trent=Players[1]:GetUnitByID(save['DOMINION_SWAP_0_TRENT_UNIT_ID']);"
    "local kill=trent.Kill;trent.Kill=function(self,...)if self.dead then error('double Trent kill')end;return kill(self,...)end;"
    "trent:Kill(false,2);GameEvents.PlayerDoTurn(2);assert(save['DOMINION_SWAP_0_ACTIVE']==0);"
    "assert(#Players[1].units==1 and Players[1].units[1].kind==30);"
    "assert(Players[1].units[1].scriptData=='script-20');"
    "assert(Map.GetPlot(5,5):GetPlotCity():GetOwner()==2)",
)

dominion_collapse_scenario(
    "Dominion collapse handles a consumed borrowed body",
    "ResetDominionCollapse('noop');assert(Dominion_StartBodySwap(0,10,1,20));"
    "Players[0]:GetUnitByID(save['DOMINION_SWAP_0_BORROWED_ID']):Kill(false,-1);"
    "Players[1]:GetUnitByID(save['DOMINION_SWAP_0_TRENT_UNIT_ID']):Kill(false,-1);"
    "GameEvents.PlayerDoTurn(2);assert(save['DOMINION_SWAP_0_ACTIVE']==0 and #Players[1].units==0)",
)

dominion_collapse_scenario(
    "Dominion collapse handles an eliminated original owner",
    "ResetDominionCollapse('noop');assert(Dominion_StartBodySwap(0,10,1,20));"
    "Players[1].alive=false;Players[1]:GetUnitByID(save['DOMINION_SWAP_0_TRENT_UNIT_ID']):Kill(false,-1);"
    "GameEvents.PlayerDoTurn(2);assert(save['DOMINION_SWAP_0_ACTIVE']==0 and #Players[0].units==0)",
)

for relative in (
    "Lua/UnaCourtCore.lua",
    "Lua/DominionCore.lua",
    "Lua/DominionBodySwap.lua",
    "Lua/UltimatePossession.lua",
):
    source = (ROOT / relative).read_text(encoding="utf-8")
    LuaRuntime().compile(source)
    print("PASS Lua 5.1 syntax", relative)

freehold_core = (ROOT / "Lua/UnaCourtCore.lua").read_text(encoding="utf-8")
dominion_core = (ROOT / "Lua/DominionCore.lua").read_text(encoding="utf-8")
assert "scriptedTrentRemovals > 0" in freehold_core
assert "scriptedTrentRemovals > 0" in dominion_core

ultimate = (ROOT / "Lua/UltimatePossession.lua").read_text(encoding="utf-8")
assert "GroupHasRequiredResources(player, targets)" in ultimate
for source in (
    (ROOT / "Lua/UnaCourtPossession.lua").read_text(encoding="utf-8"),
    (ROOT / "Lua/DominionBodySwap.lua").read_text(encoding="utf-8"),
    ultimate,
):
    assert source.count("activeTransfer = true") == 1
    assert "pcall(callback)" in source
    for field in ("level", "direction", "embarked", "fortifyTurns", "scriptData"):
        assert field in source

print("Possession safety audit scenarios passed")
