unit Unit_Cursor;
interface
uses Classes, Controls, dglOpenGL,
  Unit_ColorCoder, Unit_Controls, Unit_Pieces;


type
  TMouseArea = (maIngot, maDeck);

  //Ingame cursor that can grap pieces and move them around and across Ingot
  TPCursor = class
  private
    fX: Integer;
    fY: Integer;
    fMouseArea: TMouseArea;
    fPrevX, fPrevY: Single;
    fPickedPiece: TPiece;
  public
    CodeBelow: TColorCodeId;
    constructor Create;
    destructor Destroy; override;

    property X: Integer read fX;
    property Y: Integer read fY;

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
  fPrevX := X;
  fPrevY := Y;
  if Y < fRender.Height - DECK_HEIGHT then
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
begin
  fX := X;
  fY := Y;
  CodeBelow := fRender.CodeBelow(fX, fY);

  if not (ssLeft in Shift) then
    if fY < fRender.Height - DECK_HEIGHT then
      fMouseArea := maIngot
    else
      fMouseArea := maDeck;

  case fMouseArea of
    maIngot:  if (ssLeft in Shift) and (CodeBelow.Code in [ccNone, ccIngot]) then
                fIngot.Rotate(-(fPrevX - fX)/1, -(fPrevY - fY)/1);
    maDeck:   if Shift = [] then
              begin
                if CodeBelow.Code = ccPiece then
                  fPieces.Selected := CodeBelow.Id
                else
                  fPieces.Selected := -1;
              end;
  end;

  fPrevX := fX;
  fPrevY := fY;
end;


procedure TPCursor.Render;
var
  I: Integer;
begin
  glPushMatrix;

    glScalef(150, 150, 150);

    if fPickedPiece <> nil then
    begin
      glTranslatef(fX, fY, 0);
      fPickedPiece.Render2D;
    end;

  glPopMatrix;
end;


end.
