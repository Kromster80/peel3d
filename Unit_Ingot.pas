unit Unit_Ingot;
interface
uses dglOpenGL, Math, Unit_Vector;

type
  TIngot = class
  private
    fVerts: array of TVertice;
    fPolys: array of TPoly3;
    fWires: array of array [0..1] of Integer;
    fVtxBuf: GLuint;
    fPolyBuf: GLuint;
    fWireBuf: GLuint;

    fX: Single;
    fY: Single;
    fHead: Single;
    fPitch: Single;
    procedure Init; //Create new ingot
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromFile(aFilename: string);
    procedure Move(X,Y: Single);
    procedure Rotate(X,Y: Single);
    procedure RayIntersect(aRay, aRayVect: TVector3f; out aPoint, aNormal: TVector3f);
    procedure Render;
  end;


var
  fIngot: TIngot;


implementation
uses Unit_ColorCoder, Unit_Render;


{ TIngot }
constructor TIngot.Create;
begin
  inherited;

  glGenBuffers(1, @fVtxBuf);
  glGenBuffers(1, @fPolyBuf);
  glGenBuffers(1, @fWireBuf);
end;


destructor TIngot.Destroy;
begin
  glDeleteBuffers(1, @fVtxBuf);
  glDeleteBuffers(1, @fPolyBuf);
  glDeleteBuffers(1, @fWireBuf);

  inherited;
end;


procedure TIngot.RayIntersect(aRay, aRayVect: TVector3f; out aPoint, aNormal: TVector3f);
var
  I: Integer;
  A,B,C, Point, Normal: TVector3f;
  BestDist, NewDist: Single;
begin
  aNormal := Vector3(0,0,0);

  BestDist := MaxSingle;
  for I := Low(fPolys) to High(fPolys) do
  begin
    A.X := fVerts[fPolys[I][0]].X;
    A.Y := fVerts[fPolys[I][0]].Y;
    A.Z := fVerts[fPolys[I][0]].Z;
    B.X := fVerts[fPolys[I][1]].X;
    B.Y := fVerts[fPolys[I][1]].Y;
    B.Z := fVerts[fPolys[I][1]].Z;
    C.X := fVerts[fPolys[I][2]].X;
    C.Y := fVerts[fPolys[I][2]].Y;
    C.Z := fVerts[fPolys[I][2]].Z;

    if RayTriangleIntersect(aRay, aRayVect, A, B, C, Point, Normal) then
    begin
      NewDist := VectorLengthSqr(VectorSubtract(aRay, Point));
      if NewDist < BestDist then
      begin
        BestDist := NewDist;
        aPoint := Point;
        aNormal := Normal;
      end;
    end;
  end;
end;


procedure TIngot.Init;
const
  HeightDiv = 6;
  RadiusDiv = 12;
var
  I,K,J: Integer;
  Ang,X,Y,Z: Single;
  Off: Integer;
begin
  SetLength(fVerts, (HeightDiv * 2 - 1) * RadiusDiv + 2);
  J := 0;
  for I := -HeightDiv to HeightDiv do
  begin
    if I = -HeightDiv then
    begin
      fVerts[J] := Vertice(0, -0.5, 0, 0, -0.5, 0);
      Inc(J);
    end
    else
    if I = HeightDiv then
    begin
      fVerts[J] := Vertice(0, 0.5, 0, 0, 0.5, 0);
      Inc(J);
    end
    else
    for K := 0 to RadiusDiv - 1 do
    begin
      Ang := K / RadiusDiv * 2 * Pi;
      X := Sin(Ang) * Sin(((HeightDiv - I) / HeightDiv) / 2 * Pi) / 2;
      Y := Cos(((HeightDiv - I) / HeightDiv) / 2 * Pi) / 2;
      Z := Cos(Ang) * Sin(((HeightDiv - I) / HeightDiv) / 2 * Pi) / 2;
      fVerts[J] := Vertice(X,Y,Z, X,Y,Z);
      Inc(J);
    end;
  end;

  SetLength(fPolys, (HeightDiv - 1) * 2 * RadiusDiv * 2 + RadiusDiv * 2);

  //Caps
  J := 0;
  for K := 0 to RadiusDiv - 1 do
  begin
    fPolys[J] := Poly3(0, 1 + K, 1 + (K + 1) mod RadiusDiv);
    Inc(J);
  end;
  Off := 1 + (HeightDiv * 2 - 2) * RadiusDiv;
  for K := 0 to RadiusDiv - 1 do
  begin
    fPolys[J] := Poly3(Off + RadiusDiv, Off + K, Off + (K + 1) mod RadiusDiv);
    Inc(J);
  end;

  for I := -HeightDiv+1 to HeightDiv-2 do
  begin
    Off := 1 + (I + HeightDiv-1) * RadiusDiv;
    for K := 0 to RadiusDiv - 1 do
    begin
      fPolys[J] := Poly3(Off + K, Off + (K + 1) mod RadiusDiv, Off + RadiusDiv + K);
      Inc(J);
      fPolys[J] := Poly3(Off + RadiusDiv + K, Off + (K + 1) mod RadiusDiv, Off + RadiusDiv + (K + 1) mod RadiusDiv);
      Inc(J);
    end;
  end;

  SetLength(fWires, (HeightDiv - 1) * 2 * RadiusDiv * 2 + RadiusDiv * 2);

  //Caps
  J := 0;
  for K := 0 to RadiusDiv - 1 do
  begin
    fWires[J,0] := 0;
    fWires[J,1] := 1 + K;
    Inc(J);
  end;
  Off := 1 + (HeightDiv * 2 - 2) * RadiusDiv;
  for K := 0 to RadiusDiv - 1 do
  begin
    fWires[J,0] := Off + RadiusDiv;
    fWires[J,1] := Off + K;
    Inc(J);
  end;

  for I := -HeightDiv+1 to HeightDiv-2 do
  begin
    Off := 1 + (I + HeightDiv-1) * RadiusDiv;
    for K := 0 to RadiusDiv - 1 do
    begin
      fWires[J,0] := Off + K;
      fWires[J,1] := Off + (K + 1) mod RadiusDiv;
      Inc(J);
      fWires[J,0] := Off + K;
      fWires[J,1] := Off + RadiusDiv + K;
      Inc(J);
    end;
  end;

  glBindBuffer(GL_ARRAY_BUFFER, fVtxBuf);
  glBufferData(GL_ARRAY_BUFFER, Length(fVerts) * SizeOf(TVertice), @fVerts[0].X, GL_STREAM_DRAW);

  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, fPolyBuf);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, Length(fPolys) * SizeOf(fPolys[0]), @fPolys[0,0], GL_STREAM_DRAW);

  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, fWireBuf);
  glBufferData(GL_ELEMENT_ARRAY_BUFFER, Length(fWires) * SizeOf(fWires[0]), @fWires[0,0], GL_STREAM_DRAW);
end;


procedure TIngot.LoadFromFile(aFilename: string);
begin
  //Use blank for now
  Init;
end;


procedure TIngot.Move(X, Y: Single);
begin
  fX := fX + X;
  fY := fY + Y;
end;


procedure TIngot.Rotate(X, Y: Single);
begin
  fHead := fHead + X;
  fPitch := fPitch + Y;
end;


procedure TIngot.Render;
  procedure SetRenderColor(R,G,B: Single);
  begin
    if fRender.IsNormal then
    begin
      glColor4f(R, G, B, 1);
    end
    else
    begin
      SetColorCode(ccIngot, 0);
    end;
  end;
begin
  glRotatef(fPitch, 1, 0, 0);
  glRotatef(fHead, 0, 1, 0);
  glTranslatef(fX, fY, 0);

  SetRenderColor(0.6, 0.7, 0.6);

  glBindBuffer(GL_ARRAY_BUFFER, fVtxBuf);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, fPolyBuf);

  //Setup vertex and UV layout and offsets
  glEnableClientState(GL_VERTEX_ARRAY);
  glVertexPointer(3, GL_FLOAT, SizeOf(TVertice), Pointer(0));

  if fRender.IsNormal then
  begin
    glEnableClientState(GL_NORMAL_ARRAY);
    glNormalPointer(GL_FLOAT, SizeOf(TVertice), Pointer(12));
  end;

  //Here and above OGL requests Pointer, but in fact it's just a number (offset within Array)
  glDrawElements(GL_TRIANGLES, Length(fPolys) * Length(fPolys[0]), GL_UNSIGNED_INT, Pointer(0));

  glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientState(GL_NORMAL_ARRAY);


  SetRenderColor(0, 0, 0);
  glBindBuffer(GL_ARRAY_BUFFER, fVtxBuf);
  glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, fWireBuf);

  glEnableClientState(GL_VERTEX_ARRAY);
  glVertexPointer(3, GL_FLOAT, SizeOf(TVertice), Pointer(0));

  //Here and above OGL requests Pointer, but in fact it's just a number (offset within Array)
  glDrawElements(GL_LINES, Length(fWires) * Length(fWires[0]), GL_UNSIGNED_INT, Pointer(0));

  glDisableClientState(GL_VERTEX_ARRAY);
end;


end.
