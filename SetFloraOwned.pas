{
  Purpose: Set flora in cities to owned
  Game: The Elder Scrolls V: Skyrim
  Author: dalen <erik.gustav.dalen@gmail.com>
  Version: 2

  It is just odd that you can plunder the gardens without consequence.
}
unit userscript;

procedure SetOwnership(e: IInterface; owner: string);
var
  ownerElement: IInterface;
begin
  ownerElement := Add(e, 'Ownership', true);
  SetElementEditValues(ownerElement, 'XOWN - Owner', owner);
end;

// called for every record selected in xEdit
function Process(e: IInterface): integer;
var
  val: integer;
  ParentCell, Worldspace, PlacedObject, owner: IInterface;
  WorldspaceName: string;
  factionId: string;
begin
  Result := 0;
  factionId := nil;

  // Skip if not a REFR
  if Signature(e) <> 'REFR' then exit;

  PlacedObject := LinksTo(ElementByName(e, 'NAME - Base'));

  // Skip if placed object type is not TreeFlora*
  if not StartsStr('TreeFlora', EditorID(PlacedObject)) then exit;

  // Skip items that already has an owner
  owner := ElementByPath(e, 'Ownership');
  if owner <> nil then exit;

  ParentCell := LinksTo(ElementByName(e, 'Cell'));
  Worldspace := LinksTo(ElementByName(ParentCell, 'Worldspace'));
  WorldspaceName := EditorID(Worldspace);

  AddMessage('Processing: ' + FullPath(e));
  AddMessage('Object: ' + EditorID(PlacedObject));
  AddMessage('Worldspace: ' + WorldspaceName);

  if WorldspaceName = 'WhiterunWorld' then SetOwnership(e, '0002BE39'); // GuardFactionWhiterun
  if WorldspaceName = 'SolitudeWorld' then SetOwnership(e, '0002EBEE'); // GuardFactionSolitude
  if WorldspaceName = 'MarkarthWorld' then SetOwnership(e, '00018AAC'); // GuardFactionMarkarth
  if WorldspaceName = 'RiftenWorld' then SetOwnership(e, '000D27F2'); // GuardFactionRiften
  if WorldspaceName = 'WindhelmWorld' then SetOwnership(e, '000D27F3'); // GuardFactionWindhelm
end;

end.
