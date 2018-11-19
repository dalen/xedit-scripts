{
  Purpose: Add survival mode effects to CACO ingestables
  Game: The Elder Scrolls V: Skyrim
  Author: dalen <erik.gustav.dalen@gmail.com>
  Version: 1

  Note that these effects are defined in Update.esm, so this can be used without survival mode installed
  in that case these effects have no effect on the player.
}
unit userscript;

// Get an effect by its ID, return nil if it doesn't exist
function EffectById(effects: IwbContainer; id: string): IwbElement;
var
  i: integer;
  effect: IwbElement;
begin
  Result := nil;
  for i := 0 to ElementCount(effects) -1 do begin
    effect := ElementByIndex(effects, i);
    if EndsStr('[MGEF:' + id + ']', GetEditValue(ElementByPath(effect, 'EFID'))) then Result := effect;
  end
end;

// Check if record is a food record
function IsFood(e: IInterface): boolean;
var
  keywords: IInterface;
begin
  keywords := ElementByPath(e, 'KWDA');
  if ContainsStr(FlagValues(ElementByPath(e, 'ENIT\Flags')), 'Food Item')
  then Result := true
  else Result := false;
end;

// Return 0-4 depending on how much hunger to restore for this effect
// This depends on the hours of the CACO restore effect
function EffectHungerRestoreValue(e: IInterface): integer;
var
  effectId: string;
begin
  Result := 0;

  effectId := GetEditValue(ElementByPath(e, 'EFID'));

  // TODO: replace this with some regexp, but this works even if it repeats a bit
  if StartsStr('FoodEffectFortifyStaminaRate1hr_CACO', effectId) then Result := 1;
  if StartsStr('FoodEffectFortifyStaminaRate2hr_CACO', effectId) then Result := 2;
  if StartsStr('FoodEffectFortifyStaminaRate3hr_CACO', effectId) then Result := 3;
  if StartsStr('FoodEffectFortifyStaminaRate4hr_CACO', effectId) then Result := 4;
  
  if StartsStr('FoodEffectFortifyStamina1hr_CACO', effectId) then Result := 1;
  if StartsStr('FoodEffectFortifyStamina2hr_CACO', effectId) then Result := 2;
  if StartsStr('FoodEffectFortifyStamina3hr_CACO', effectId) then Result := 3;
  if StartsStr('FoodEffectFortifyStamina4hr_CACO', effectId) then Result := 4;
  
  if StartsStr('FoodEffectFortifyHealRate1hr_CACO', effectId) then Result := 1;
  if StartsStr('FoodEffectFortifyHealRate2hr_CACO', effectId) then Result := 2;
  if StartsStr('FoodEffectFortifyHealRate3hr_CACO', effectId) then Result := 3;
  if StartsStr('FoodEffectFortifyHealRate4hr_CACO', effectId) then Result := 4;

  if StartsStr('FoodEffectFortifyHealth1hr_CACO', effectId) then Result := 1;
  if StartsStr('FoodEffectFortifyHealth2hr_CACO', effectId) then Result := 2;
  if StartsStr('FoodEffectFortifyHealth3hr_CACO', effectId) then Result := 3;
  if StartsStr('FoodEffectFortifyHealth4hr_CACO', effectId) then Result := 4;

  if StartsStr('FoodEffectFortifyMagickaRate1hr_CACO', effectId) then Result := 1;
  if StartsStr('FoodEffectFortifyMagickaRate2hr_CACO', effectId) then Result := 2;
  if StartsStr('FoodEffectFortifyMagickaRate3hr_CACO', effectId) then Result := 3;
  if StartsStr('FoodEffectFortifyMagickaRate4hr_CACO', effectId) then Result := 4;

  if StartsStr('FoodEffectFortifyMagicka1hr_CACO', effectId) then Result := 1;
  if StartsStr('FoodEffectFortifyMagicka2hr_CACO', effectId) then Result := 2;
  if StartsStr('FoodEffectFortifyMagicka3hr_CACO', effectId) then Result := 3;
  if StartsStr('FoodEffectFortifyMagicka4hr_CACO', effectId) then Result := 4;
end;

// Return 0-4 depending on how much hunger this item should restore
// This depends on the largest CACO restore effect of the item
function ItemHungerRestoreValue(e: IInterface): integer;
var
  i, val: integer;
  effects: IInterface;
begin
  Result := 0;

  effects := ElementByPath(e, 'Effects');

  for i := 0 to ElementCount(effects) -1 do begin
    val := EffectHungerRestoreValue(ElementByIndex(effects, i));

    if val > Result then Result := val;
  end
end;


// called for every record selected in xEdit
function Process(e: IInterface): integer;
var
  val: integer;
  effects, effect, effectId: IInterface;
begin
  Result := 0;

  if not IsFood(e) then exit;

  AddMessage('Processing: ' + FullPath(e));
  AddMessage('Restore value: ' + IntToStr(ItemHungerRestoreValue(e)));

  val := ItemHungerRestoreValue(e);
  if val = 0 then exit;

  effects := Add(e, 'Effects', true);

  // Find an existing survival mode effect to replace it, if not present, add a new effect
  if EffectById(effects, '01002EE1') <> nil then effect := EffectById(effects, '01002EE1')
  else if EffectById(effects, '01002EE2') <> nil then effect := EffectById(effects, '01002EE2')
  else if EffectById(effects, '01002EE3') <> nil then effect := EffectById(effects, '01002EE3')
  else if EffectById(effects, '01002EE4') <> nil then effect := EffectById(effects, '01002EE4')
  else effect := ElementAssign(effects, HighInteger, nil, false);

  effectId := ElementByPath(effect, 'EFID');
  case val of
    1: SetEditValue(effectId, '01002EE1'); // Restore Hunger Very Small
    2: SetEditValue(effectId, '01002EE2'); // Restore Hunger Small
    3: SetEditValue(effectId, '01002EE3'); // Restore Hunger Medium
    4: SetEditValue(effectId, '01002EE4'); // Restore Hunger Large
  end;
end;

end.