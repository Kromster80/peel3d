unit Unit_Cursor;
interface
uses Classes, Controls, dglOpenGL,
  Unit_ColorCoder, Unit_Controls, Unit_Pieces, Unit_Vector;


type
  TMouseArea = (maIngot, maDeck);

  //Ingame cursor that can grap pieces and move them around and across Ingot
  TPCursor = class
  private
    fPosX: Integer;
    fPosY: Integer;
    fMouseArea: TMouseArea;
    fPrevX, fPrevY: Single;
    fPickedPiece: TPiece;

    fIngotPoint: TVector3f;
    fIngotNormal: TVector3f;
  public
    CodeBelow: TColorCodeId;
    constructor Create;
    destructor Destroy; override;

    property PosX: Integer read fPosX;
    property PosY: Integer read fPosY;

    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MouseMove(Shift: TShiftState; X, Y: Integer);

    procedure Render;
  end;


var
  fCursor: TPCursor;


implementation
uses Unit_Defaults, Unit_Deck, Unit_Ingot, Unit_Session, Unit_Render;


{ TCursor }
constructor TPCursor.Create;
begin
  inherited;

end;


destructor TPCursor.Destroy;
begin

  inherited;
end;


procedure TPCursor.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  fPosX := X;
  fPosY := Y;

  fPrevX := fPosX;
  fPrevY := fPosY;

  if fPosY < fRender.Height - DECK_HEIGHT then
    fMouseArea := maIngot
  else
    fMouseArea := maDeck;

  case fMouseArea of
    maIngot:  ;//fIngot.MouseDown;
    maDeck:   if CodeBelow.Code = ccPiece then
              begin
                fPickedPiece := fPieces.PieceById(CodeBelow.Id);
                fPickedPiece.Location := plCursor;

                fDeck.PiecePick(fPickedPiece);
              end;
  end;
end;


procedure TPCursor.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  RayStart, RayEnd: TVector3f;
begin
  fPosX := X;
  fPosY := Y;
  CodeBelow := fRender.CodeBelow(fPosX, fPosY);

  if not (ssLeft in Shift) then
    if fPosY < fRender.Height - DECK_HEIGHT then
      fMouseArea := maIngot
    else
      fMouseArea := maDeck;

  case fMouseArea of
    maIngot:  begin
                if (ssLeft in Shift) and (CodeBelow.Code in [ccNone, ccIngot]) then
                  fIngot.Rotate(-(fPrevX - fPosX)/1, -(fPrevY - fPosY)/1);

                if (CodeBelow.Code = ccIngot) then
                begin
                  fRender.GetRay(fPosX, fPosY, RayStart, RayEnd);
                  fIngot.RayIntersect(RayStart, RayEnd, fIngotPoint, fIngotNormal);
                end;
              end;

    maDeck:   if Shift = [] then
              begin
                if CodeBelow.Code = ccPiece then
                  fPieces.Selected := CodeBelow.Id
                else
                  fPieces.Selected := -1;
              end;
  end;

  fPrevX := fPosX;
  fPrevY := fPosY;
end;


procedure TPCursor.Render;
var
  V: TVector3f;
begin
  if (fMouseArea = maDeck)
  or ((fMouseArea = maIngot) and (CodeBelow.Code = ccNone)) then
  begin
    if fPickedPiece = nil then Exit;

    fRender.Switch(rm2D);
    glPushMatrix;

      glTranslatef(fPosX, fPosY, 0);
      glScalef(150, 150, 150);
      fPickedPiece.Render2D;

    glPopMatrix;
  end;

  if fIngotNormal.Y <> 0 then
  begin
    fRender.Switch(rm3D);

    V := VectorAdd(fIngotPoint, VectorScale(fIngotNormal, 0.25));
    glColor4f(1,1,0,1);
    glBegin(GL_LINES);
      glVertex3fv(@fIngotPoint);
      glVertex3fv(@V);
    glEnd;
  end;
end;


end.
