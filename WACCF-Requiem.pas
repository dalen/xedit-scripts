{
    Patch generator for Requiem and
    Weapons, Armor, Clothing and Clutter Fixes 
}
unit RequiemWACCFPatcher;

const
  requiemFile = 'Requiem.esp';
  waccfFile = 'Weapons Armor Clothing & Clutter Fixes.esp';

var
  patch, requiem, waccf: IwbFile;

// Check if a record is already reqtified
function IsAlreadyReqtified(r: IwbMainRecord): boolean;
var
  i: integer;
  keywords: IwbElement;
begin
  Result := HasKeyword(r, 'REQ_KW_AlreadyReqtified');
end;

// Check if the record has the specified keyword
function HasKeyword(r: IwbMainRecord; keyword: string): boolean;
var
  i: integer;
  keywords: IwbElement;
begin
  Result := false;
  keywords :=  ElementByPath(r, 'KWDA');
  if keywords <> nil then begin
    for i := 0 to Pred(ElementCount(keywords)) do begin
      if StartsStr(keyword, GetEditValue(ElementByIndex(keywords, i))) then begin
        Result := true;
        break;
      end;
    end;
  end;
end;

// Check if the record has the specified flag at path
function HasFlag(r: IwbMainRecord; path: string; flag: string): boolean;
var
  i: integer;
  flags: IwbElement;
begin
  Result := false;
  flags :=  ElementByPath(r, path);
  if flags <> nil then begin
    for i := 0 to Pred(ElementCount(flags)) do begin
      if StartsStr(flag, GetEditValue(ElementByIndex(flags, i))) then begin
        Result := true;
        break;
      end;
    end;
  end;
end;


// If element at path has not changed in r1 compared to master, but has in r2, then copy it from r2 to patch
// Used to copy requiem changes when WACCF just has the same as Skyrim
procedure CopyIfChanged(path: string; r1: IInterface; r2: IInterface; patch: IwbMainRecord);
var
  masterRecord: IwbMainRecord;
  masterElement: IwbElement;
  r1Element: IwbElement;
  r2Element: IwbElement;
begin
  masterRecord := Master(ContainingMainRecord(r1));
  if not Assigned(masterRecord) then exit;

  masterElement := ElementByPath(masterRecord, path);
  if not Assigned(masterElement) then exit;

  r1Element := ElementByPath(ContainingMainRecord(r1), path);
  if not Assigned(r1Element) then exit;

  r2Element := ElementByPath(ContainingMainRecord(r2), path);
  if not Assigned(r2Element) then exit;

  if (GetEditValue(masterElement) = GetEditValue(r1Element)) and (GetEditValue(masterElement) <> GetEditValue(r2Element)) then begin
    wbCopyElementToRecord(r2Element, patch, false, true);
  end;
end;



// Merge keyword list, but make sure to only use WeapMaterial from WACCF if they differ from Requiem
// Same handling of ArmorType keyword as with material
// VendorItem keywords are only copied from WACCF
procedure MergeKeyWords(e1: IwbElement; e2: IwbElement; eP: IInterface);
var
  i: integer;
  keywords: TStringList;
  k: IInterface;
  dest: IwbElement;
  material: boolean;
  armorType: boolean;
begin
  material := false;
  armorType := false;
  keywords := TStringList.Create;
  keywords.Sorted := true;
  keywords.Duplicates := dupIgnore;
  for i := 0 to Pred(ElementCount(e1)) do begin
    if StartsStr('WeapMaterial', GetEditValue(ElementByIndex(e1, i))) then material := true;
    if StartsStr('WAF_WeapMaterial', GetEditValue(ElementByIndex(e1, i))) then material := true;
    if StartsStr('ArmorMaterial', GetEditValue(ElementByIndex(e1, i))) then material := true;
    if StartsStr('ArmorHeavy', GetEditValue(ElementByIndex(e1, i))) then armorType := true;
    if StartsStr('ArmorLight', GetEditValue(ElementByIndex(e1, i))) then armorType := true;
    if StartsStr('ArmorClothing', GetEditValue(ElementByIndex(e1, i))) then armorType := true;
    keywords.Add(GetEditValue(ElementByIndex(e1, i)));
  end;
  for i := 0 to Pred(ElementCount(e2)) do begin
    if StartsStr('VendorItem', GetEditValue(ElementByIndex(e2, i))) then continue;
    if StartsStr('WeapMaterial', GetEditValue(ElementByIndex(e2, i))) and material then continue;
    if StartsStr('WAF_WeapMaterial', GetEditValue(ElementByIndex(e2, i))) and material then continue;
    if StartsStr('ArmorMaterial', GetEditValue(ElementByIndex(e2, i))) and material then continue;
    if StartsStr('ArmorHeavy', GetEditValue(ElementByIndex(e2, i))) and armorType then continue;
    if StartsStr('ArmorLight', GetEditValue(ElementByIndex(e2, i))) and armorType then continue;
    if StartsStr('ArmorClothing', GetEditValue(ElementByIndex(e2, i))) and armorType then continue;
    keywords.Add(GetEditValue(ElementByIndex(e2, i)));
  end;

  // Clear destination
  RemoveElement(eP, 'KWDA');
  dest := Add(eP, 'KWDA', true);

  for i := 0 to Pred(keywords.Count) do begin
    k := ElementAssign(dest, HighInteger, nil, false);
    SetEditValue(k, keywords[i]);
  end;
end;

procedure HandleRecord(e: IwbMainRecord; eR: IwbMainRecord; eP: IwbMainRecord);
var
  i: integer;
  element: IwbElement;
begin
  // Iterate over elements in record and copy the Requiem ones as needed
  for i := 0 to Pred(ElementCount(eR)) do begin
    element := ElementByIndex(eR, i);
    
    // Always use Requiem editor ID
    if ShortName(element) = 'EDID - Editor ID' then wbCopyElementToRecord(element, eP, false, true);

    if Signature(e) = 'ALCH' then begin
      if ShortName(element) = 'Effects' then wbCopyElementToRecord(element, eP, false, true);
      if ShortName(element) = 'ENIT - Effect Data' then begin
        // If Requiem has it set to no auto calc, but WACCF not, then use requiem value and ENIT data
        if HasFlag(eR, 'ENIT - Effect Data', 'No Auto-Calc') and (not HasFlag(e, 'ENIT - Effect Data', 'No Auto-Calc')) then begin
          wbCopyElementToRecord(element, eP, false, true);
        end;
      end;
    end;

    if Signature(e) = 'AMMO' then begin
      if ShortName(element) = 'DESC - Description' then wbCopyElementToRecord(element, eP, false, true);
      if ShortName(element) = 'KWDA - Keywords' then MergeKeywords(ElementBySignature(e, 'KWDA'), element, eP);
      if ShortName(element) = 'DATA - Data' then begin
        if IsAlreadyReqtified(eR) then begin
          wbCopyElementToRecord(element, eP, false, true);
        end else begin
          CopyIfChanged('DATA - Data\Value', e, eR, eP);
          CopyIfChanged('DATA - Data\Weight', e, eR, eP);
          CopyIfChanged('DATA - Data\Damage', e, eR, eP);
        end;
      end;
    end;

    if Signature(e) = 'ARMO' then begin
      if ShortName(element) = 'Record Header' then begin
        CopyIfChanged('Record Header\Record Flags', e, eR, eP);
      end;
      if ShortName(element) = 'KWDA - Keywords' then MergeKeywords(ElementBySignature(e, 'KWDA'), element, eP);
      if ShortName(element) = 'EITM - Object Effect' then wbCopyElementToRecord(element, eP, false, true);
      if ShortName(element) = 'VMAD - Virtual Machine Adapter' then wbCopyElementToRecord(element, eP, false, true);
      if ShortName(element) = 'DESC - Description' then wbCopyElementToRecord(element, eP, false, true);
    end;

    if Signature(e) = 'ARMA' then begin
      if ShortName(element) = 'Male world model' then wbCopyElementToRecord(element, eP, false, true);
      if ShortName(element) = 'Female world model' then wbCopyElementToRecord(element, eP, false, true);
      if ShortName(element) = 'Male 1st Person' then wbCopyElementToRecord(element, eP, false, true);
      if ShortName(element) = 'Female 1st Person' then wbCopyElementToRecord(element, eP, false, true);
      if ShortName(element) = 'Additional Races' then wbCopyElementToRecord(element, eP, false, true);
    end;

    if Signature(e) = 'COBJ' then begin
      if ShortName(element) = 'Conditions' then wbCopyElementToRecord(element, eP, false, true);
    end;

    if Signature(e) = 'INGR' then begin
      if ShortName(element) = 'ENIT - Effect Data' then wbCopyElementToRecord(element, eP, false, true);
      if ShortName(element) = 'Effects' then wbCopyElementToRecord(element, eP, false, true);
      if ShortName(element) = 'KWDA - Keywords' then MergeKeywords(ElementBySignature(e, 'KWDA'), element, eP);
    end;

    if Signature(e) = 'LIGH' then begin
      if ShortName(element) = 'DATA - DATA' then wbCopyElementToRecord(element, eP, false, true);
      if ShortName(element) = 'FNAM - Fade value' then wbCopyElementToRecord(element, eP, false, true);
    end;

    if Signature(e) = 'MISC' then begin
      if ShortName(element) = 'DATA - Data' then begin
        // Use Requiem changes like gold weight and Aretinos heirloom value
        CopyIfChanged('DATA - Data\Value', e, eR, eP);
      end;
      if ShortName(element) = 'KWDA - Keywords' then MergeKeywords(ElementBySignature(e, 'KWDA'), element, eP);
    end;

    if Signature(e) = 'WEAP' then begin
      if ShortName(element) = 'Record Header' then begin
        CopyIfChanged('Record Header\Record Flags', e, eR, eP);
      end;
      if ShortName(element) = 'KWDA - Keywords' then MergeKeywords(ElementBySignature(e, 'KWDA'), element, eP);
      if ShortName(element) = 'VMAD - Virtual Machine Adapter' then wbCopyElementToRecord(element, eP, false, true);
      if ShortName(element) = 'DESC - Description' then wbCopyElementToRecord(element, eP, false, true);
      if ShortName(element) = 'EAMT - Enchantment Amount' then wbCopyElementToRecord(element, eP, false, true);
      if ShortName(element) = 'EITM - Object Effect' then wbCopyElementToRecord(element, eP, false, true);
      if ShortName(element) = 'CNAM - Template' then begin
        CopyIfChanged('CNAM - Template', e, eR, eP);
      end;

      // Copy all data on retified items, on non reqtified only copy part of the data
      if IsAlreadyReqtified(eR) then begin
        if ShortName(element) = 'DATA - Game Data' then wbCopyElementToRecord(element, eP, false, true);
        if ShortName(element) = 'DNAM - Data' then wbCopyElementToRecord(element, eP, false, true);
      end else begin
        // Check if Requiem element has Flags2, then copy them
        // Mostly the "NPC's use ammo flag on bows"
        if ShortName(element) = 'DNAM - Data' then begin
          if ElementExists(element, 'Flags2') then wbCopyElementToRecord(ElementByPath(element, 'Flags2'), eP, false, true);
        end;
      end;
    end;
  end;
end;

function Initialize: integer;
var
  i: integer;
  e: IInterface; // WACCF element
  eR: IInterface; // Requiem element
  eP: IInterface; // Patch element
  o: IInterface; // Override
begin
  // create a new patch plugin if needed
  if not Assigned(patch) then
    patch := AddNewFile;

  if not Assigned(patch) then
    exit;
  
  AddMasterIfMissing(patch, 'Skyrim.esm');
  AddMasterIfMissing(patch, 'Update.esm');
  AddMasterIfMissing(patch, 'Dawnguard.esm');
  AddMasterIfMissing(patch, 'Dragonborn.esm');
  AddMasterIfMissing(patch, 'HearthFires.esm');
  AddMasterIfMissing(patch, waccfFile);
  AddMasterIfMissing(patch, requiemFile);
  waccf := MasterByIndex(patch, 5);
  requiem := MasterByIndex(patch, 6);

  // iterate over all records in waccf
  for i := 0 to Pred(RecordCount(waccf)) do begin
    e := RecordByIndex(waccf, i);

    if IsWinningOverride(e) then continue;

    // Skip certain types of records entirely
    if Signature(e) = 'LSCR' then continue;
    if Signature(e) = 'LVLI' then continue;
    if Signature(e) = 'NPC_' then continue;
    if Signature(e) = 'OTFT' then continue;
    if Signature(e) = 'PERK' then continue;
    if Signature(e) = 'PROJ' then continue;
    if Signature(e) = 'TXST' then continue;
    if Signature(e) = 'CELL' then continue;
    if Signature(e) = 'CONT' then continue;
    if Signature(e) = 'ENCH' then continue;

    eR := RecordByFormID(requiem, FixedFormID(e), false);
    if not Assigned(eR) then continue;
    if GetFileName(eR) <> requiemFile then continue;

    // For Ingestibles, skip potions and blackmarket items (Skooma)
    if Signature(e) = 'ALCH' then begin
      if HasKeyword(e, 'VendorItemPotion') then continue;
      if HasKeyword(eR, 'REQ_KW_VendorItem_BlackMarket') then continue;
    end;

    //AddMessage('Processing: ' + FullPath(eR));

    AddRequiredElementMasters(e, patch, true);
    AddRequiredElementMasters(eR, patch, true);
    eP := wbCopyElementToFile(e, patch, false, true);
    HandleRecord(e, eR, eP);
  end;
end;

end.