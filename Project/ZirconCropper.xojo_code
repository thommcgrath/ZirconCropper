#tag Class
Protected Class ZirconCropper
Inherits ArtisanKit.Control
	#tag Event
		Function MouseDown(X As Integer, Y As Integer) As Boolean
		  Self.Invalidate()
		  If Self.mSource Is Nil Then
		    Self.mHandleMouseActions = False
		    Return True
		  End If
		  
		  Self.mHandleMouseActions = True
		  Var Point As New Xojo.Point(X,Y)
		  Self.mMouseDownPos = Point.Clone
		  Self.mMousePoint = Point.Clone
		  If Self.mZoomOutButtonRect <> Nil And Self.mZoomOutButtonRect.Contains(Point) Then
		    Self.mState = StateZoomingOut
		    Self.StartZoomTimer()
		  ElseIf Self.mZoomInButtonRect <> Nil And Self.mZoomInButtonRect.Contains(Point) Then
		    Self.mState = StateZoomingIn
		    Self.StartZoomTimer()
		  ElseIf Self.mZoomThumbRect <> Nil And Self.mZoomThumbRect.Contains(Point) Then
		    Self.mState = StateZoomingManually
		    Self.mMouseDownOffset = Self.mZoomThumbRect.LocalPoint(Point)
		  ElseIf Self.mZoomTrackRect <> Nil And Self.mZoomTrackRect.Contains(Point) Then
		    Self.mState = StateZoomingTrack
		    Self.StartZoomTimer()
		  Else
		    Self.mState = StateDraggingPic
		    Self.mMouseDownOffset = Self.mSourceOffset.Clone
		  End If
		  Return True
		End Function
	#tag EndEvent

	#tag Event
		Sub MouseDrag(X As Integer, Y As Integer)
		  If Self.mHandleMouseActions = False Then
		    Return
		  End If
		  
		  Self.mMousePoint = New Xojo.Point(X,Y)
		  
		  Select Case Self.mState
		  Case StateZoomingManually
		    Var MinZoomPos As Integer = Self.mZoomTrackRect.Left
		    Var MaxZoomPos As Integer = Self.mZoomTrackRect.Right - ControllerSize
		    X = X + (Self.mMouseDownOffset.X * -1)
		    Var ZoomPercent As Double = (X - MinZoomPos) / (MaxZoomPos - MinZoomPos)
		    Var Level As Double = Self.mMinimumZoom + ((1 - Self.mMinimumZoom) * ZoomPercent)
		    Self.SetZoomLevel(Level)
		  Case StateDraggingPic
		    Var DiffX As Integer = X - Self.mMouseDownPos.X
		    Var DiffY As Integer = Y - Self.mMouseDownPos.Y
		    Self.mSourceOffset.X = Max(Min(Self.mMouseDownOffset.X + DiffX,Self.mSourceOffsetMaxX),Self.mSourceOffsetMinX)
		    Self.mSourceOffset.Y = Max(Min(Self.mMouseDownOffset.Y + DiffY,Self.mSourceOffsetMaxY),Self.mSourceOffsetMinY)
		    
		    Self.Invalidate()
		  End Select
		End Sub
	#tag EndEvent

	#tag Event
		Sub MouseUp(X As Integer, Y As Integer)
		  If Self.mHandleMouseActions = False Then
		    Return
		  End If
		  
		  Self.mMousePoint = New Xojo.Point(X,Y)
		  Self.mState = StateNone
		  Self.StopZoomTimer()
		  Self.Invalidate()
		End Sub
	#tag EndEvent

	#tag Event
		Sub Paint(G As Graphics, Areas() As Xojo.Rect, Highlighted As Boolean)
		  #pragma Unused Areas
		  #pragma Unused Highlighted
		  
		  Var UseDarkMode As Boolean
		  #if XojoVersion >= 2019.03
		    G.ClearRectangle(0, 0, G.Width, G.Height)
		    UseDarkMode = Color.IsDarkMode
		  #else
		    G.ClearRect(0, 0, G.Width, G.Height)
		    UseDarkMode = IsDarkMode()
		  #endif
		  
		  If Self.mHasBackgroundColor Then
		    G.DrawingColor = Self.mBackgroundColor
		    G.FillRectangle(0, 0, G.Width, G.Height)
		  End If
		  
		  If Self.mSource Is Nil Then
		    Return
		  End If
		  
		  Var ForeColor, AltColor As Color
		  If Self.mHasBackgroundColor Then
		    If ArtisanKit.ColorBrightness(Self.mBackgroundColor) > 127 Then
		      ForeColor = &c000000
		      AltColor = &cFFFFFF
		    Else
		      ForeColor = &cFFFFFF
		      AltColor = &c000000
		    End If
		  Else
		    If UseDarkMode Then
		      ForeColor = &cFFFFFF
		      AltColor = &c000000
		    Else
		      ForeColor = &c000000
		      AltColor = &cFFFFFF
		    End If
		  End If
		  
		  Var ZoomLevel As Double = Min(Max(Self.mMinimumZoom,Self.mZoomLevel),1) * Self.mFrameScale
		  Var FrameSpace As New Xojo.Rect(PaddingSize,PaddingSize,G.Width - (PaddingSize * 2),G.Height - ((PaddingSize * 3) + ControllerSize))
		  Var FrameRect As New Xojo.Rect(FrameSpace.HorizontalCenter - Round(Self.mFrameSize.Width / 2),FrameSpace.VerticalCenter - Round(Self.mFrameSize.Height / 2),Self.mFrameSize.Width,Self.mFrameSize.Height)
		  Var PicSize As New Xojo.Size(Round(Self.mSource.Width * ZoomLevel),Round(Self.mSource.Height * ZoomLevel))
		  Var PicRect As New Xojo.Rect(FrameSpace.HorizontalCenter - Round(PicSize.Width / 2),FrameSpace.VerticalCenter - Round(PicSize.Height / 2),PicSize.Width,PicSize.Height)
		  PicRect.Origin.X = PicRect.Origin.X + Self.mSourceOffset.X
		  PicRect.Origin.Y = PicRect.Origin.Y + Self.mSourceOffset.Y
		  
		  Var Scaled As New Picture(PicRect.Width, PicRect.Height)
		  Scaled.Graphics.DrawPicture(Self.mSource, 0, 0, Scaled.Width, Scaled.Height, 0, 0, Self.mSource.Width, Self.mSource.Height)
		  Scaled = Self.PostProcess(Scaled)
		  
		  G.Transparency = 75
		  G.DrawPicture(Scaled, PicRect.Left, PicRect.Top)
		  G.Transparency = 0
		  #if XojoVersion >= 2019.03
		    G.ClearRectangle(FrameRect.Left, FrameRect.Top, FrameRect.Width, FrameRect.Height)
		  #else
		    G.ClearRect(FrameRect.Left, FrameRect.Top, FrameRect.Width, FrameRect.Height)
		  #endif
		  If Self.mHasBackgroundColor Then
		    G.DrawingColor = Self.mBackgroundColor
		    G.FillRectangle(FrameRect.Left, FrameRect.Top, FrameRect.Width, FrameRect.Height)
		  End If
		  G.DrawPicture(Scaled, FrameRect.Left, FrameRect.Top, FrameRect.Width, FrameRect.Height, FrameRect.Left - PicRect.Left, FrameRect.Top - PicRect.Top, FrameRect.Width, FrameRect.Height)
		  G.Transparency = 50
		  G.DrawingColor = ForeColor
		  G.DrawRectangle(FrameRect.Left - 1,FrameRect.Top - 1,FrameRect.Width + 2,FrameRect.Height + 2)
		  Self.DrawController(G, ForeColor)
		  G.Transparency = 50
		  G.DrawingColor = AltColor
		  G.DrawRectangle(FrameRect.Left,FrameRect.Top,FrameRect.Width,FrameRect.Height)
		End Sub
	#tag EndEvent

	#tag Event
		Sub Resized()
		  Self.UpdateMetrics()
		  Self.SetZoomLevel(Self.mZoomLevel)
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub Clear()
		  Self.mSource = Nil
		  Self.Invalidate()
		  RaiseEvent SourceImagePresented(Nil)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Crop() As Picture
		  If Self.mSource Is Nil Then
		    Return Nil
		  End If
		  
		  Var SourceSize As New Xojo.Size(Self.mSource.Width,Self.mSource.Height)
		  Var SourceChunkSize As New Xojo.Size(Self.mDesiredSize.Width / Self.mZoomLevel,Self.mDesiredSize.Height / Self.mZoomLevel)
		  Var ChunkRatio As Double = SourceChunkSize.Width / SourceChunkSize.Height
		  If SourceChunkSize.Width > SourceSize.Width Then
		    SourceChunkSize.Width = SourceSize.Width
		    SourceChunkSize.Height = SourceChunkSize.Width * ChunkRatio
		  ElseIf SourceChunkSize.Height > SourceSize.Height Then
		    SourceChunkSize.Height = SourceSize.Height
		    SourceChunkSize.Width = SourceChunkSize.Height / ChunkRatio
		  End If
		  
		  Var SourceRect As New Xojo.Rect
		  SourceRect.Size = SourceChunkSize
		  SourceRect.Left = ((SourceSize.Width / 2) - (SourceChunkSize.Width / 2)) - ((Self.mSourceOffset.X / Self.mZoomLevel) / Self.mFrameScale)
		  SourceRect.Top = ((SourceSize.Height / 2) - (SourceChunkSize.Height / 2)) - ((Self.mSourceOffset.Y / Self.mZoomLevel) / Self.mFrameScale)
		  SourceRect.Left = Min(Max(SourceRect.Left,0),SourceSize.Width - SourceChunkSize.Width)
		  SourceRect.Top = Min(Max(SourceRect.Top,0),SourceSize.Height - SourceChunkSize.Height)
		  
		  Var Bitmaps(2) As Picture
		  For Factor As Integer = 1 To 3
		    Var Image As New Picture(Self.mDesiredSize.Width * Factor, Self.mDesiredSize.Height * Factor)
		    Image.HorizontalResolution = 72 * Factor
		    Image.VerticalResolution = 72 * Factor
		    Image.Graphics.DrawPicture(Self.mSource, 0, 0, Image.Width, Image.Height, SourceRect.Left, SourceRect.Top, SourceRect.Width, SourceRect.Height)
		    Bitmaps(Factor - 1) = Image
		  Next
		  
		  Return New Picture(Bitmaps(0).Width, Bitmaps(0).Height, Bitmaps)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Attributes( Hidden ) Private Sub DrawController(G As Graphics, ForeColor As Color)
		  Var TrackOuterWidth As Integer = Self.mControllerRect.Width
		  Var TrackOuterHeight As Integer = Self.mControllerRect.Height
		  Var TrackOuterArc As Integer = Min(TrackOuterWidth, TrackOuterHeight)
		  Var TrackInnerWidth As Integer = TrackOuterWidth - 36
		  Var TrackInnerHeight As Integer = TrackOuterHeight - 4
		  Var TrackInnerArc As Integer = Min(TrackInnerWidth, TrackInnerHeight)
		  
		  Var Mask As Picture = G.NewPicture(Self.mControllerRect.Width, Self.mControllerRect.Height)
		  Mask.Graphics.DrawingColor = &cFFFFFF
		  Mask.Graphics.FillRectangle(0, 0, Self.mControllerRect.Width, Self.mControllerRect.Height)
		  Mask.Graphics.DrawingColor = &c000000
		  Mask.Graphics.FillRoundRectangle(0, 0, TrackOuterWidth, TrackOuterHeight, TrackOuterArc, TrackOuterArc)
		  Mask.Graphics.DrawingColor = &cFFFFFF
		  Mask.Graphics.FillRoundRectangle(18, 2, TrackInnerWidth, TrackInnerHeight, TrackInnerArc, TrackInnerArc)
		  Mask.Graphics.FillRectangle(5, 7, 8, 2) // Minus
		  Mask.Graphics.FillRectangle(TrackOuterWidth - 13, 7, 8, 2) // Plus Horizontal
		  Mask.Graphics.FillRectangle(TrackOuterWidth - 10, 4, 2, 8) // Plus Vertical
		  
		  Var ThumbRect As Xojo.Rect = Self.mZoomThumbRect.LocalRect(Self.mControllerRect)
		  Var ThumbWidth As Integer = ThumbRect.Width - 8
		  Var ThumbHeight As Integer = ThumbRect.Height - 8
		  Var ThumbArc As Integer = Min(ThumbWidth, ThumbHeight)
		  Mask.Graphics.DrawingColor = &c000000
		  Mask.Graphics.FillRoundRectangle(ThumbRect.Left + 4, ThumbRect.Top + 4, ThumbWidth, ThumbHeight, ThumbArc, ThumbArc)
		  
		  Var Controller As Picture = G.NewPicture(Self.mControllerRect.Width, Self.mControllerRect.Height)
		  Controller.Graphics.DrawingColor = ForeColor
		  Controller.Graphics.FillRectangle(0, 0, Controller.Width, Controller.Height)
		  Controller.ApplyMask(Mask)
		  
		  G.DrawPicture(Controller, Self.mControllerRect.Left, Self.mControllerRect.Top, Self.mControllerRect.Width, Self.mControllerRect.Height, 0, 0, Controller.Width, Controller.Height)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Attributes( Hidden ) Private Function FillWithin(Source As Xojo.Size, Destination As Xojo.Size) As Xojo.Size
		  If Source.Width <= Destination.Width And Source.Height <= Destination.Height Then
		    Return Source.Clone
		  End If
		  
		  Var DestinationRatio As Double = Destination.Width / Destination.Height
		  Var SourceRatio As Double = Source.Width / Source.Height
		  Var Result As Xojo.Size = Source.Clone
		  
		  If DestinationRatio >= SourceRatio Then
		    Result.Width = Min(Destination.Width,Source.Width)
		    Result.Height = Result.Width / SourceRatio
		  Else
		    Result.Height = Min(Destination.Height,Source.Height)
		    Result.Width = Result.Height * SourceRatio
		  End If
		  
		  Return Result
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Attributes( Hidden ) Private Function FitWithin(Source As Xojo.Size, Destination As Xojo.Size) As Xojo.Size
		  Var SourceRatio As Double = Source.Width / Source.Height
		  Var Result As Xojo.Size = Source.Clone
		  
		  Do Until Result.Width <= Destination.Width And Result.Height <= Destination.Height
		    If Result.Width > Destination.Width Then
		      Result.Width = Destination.Width
		      Result.Height = Result.Width / SourceRatio
		      Continue
		    End If
		    If Result.Height > Destination.Height Then
		      Result.Height = Destination.Height
		      Result.Width = Result.Height * SourceRatio
		      Continue
		    End If
		  Loop
		  
		  Return Result
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function PostProcess(ScaledImage As Picture) As Picture
		  Return ScaledImage
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Present(Source As Picture, DesiredWidth As Integer, DesiredHeight As Integer)
		  If Source Is Nil Then
		    Return
		  End If
		  
		  RaiseEvent SourceImagePresenting(Source)
		  
		  Self.mSource = Source
		  Self.mSourceOffset = New Xojo.Point(0,0)
		  Self.mDesiredSize = New Xojo.Size(DesiredWidth,DesiredHeight)
		  Self.Invalidate()
		  Self.UpdateMetrics()
		  Self.SetZoomLevel(Self.mMinimumZoom)
		  
		  RaiseEvent SourceImagePresented(Source)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Attributes( Hidden ) Private Sub SetZoomLevel(Level As Double)
		  If Self.mSource Is Nil Then
		    Return
		  End If
		  
		  Level = Min(Max(Level,Self.mMinimumZoom),1)
		  
		  Var MinZoomPos As Integer = Self.mZoomTrackRect.Left
		  Var MaxZoomPos As Integer = Self.mZoomTrackRect.Right - ControllerSize
		  Var ZoomPercent As Double = (Level - Self.mMinimumZoom) / (1 - Self.mMinimumZoom)
		  Var Pos As Integer = MinZoomPos + ((MaxZoomPos - MinZoomPos) * ZoomPercent)
		  Self.mZoomThumbRect = New Xojo.Rect(Pos,Self.mZoomTrackRect.Top,ControllerSize,ControllerSize)
		  Self.mZoomLevel = Level
		  
		  Level = Level * Self.mFrameScale
		  Var PicSize As New Xojo.Size(Round(Self.mSource.Width * Level),Round(Self.mSource.Height * Level))
		  #if XojoVersion >= 2020.01
		    Self.mSourceOffsetMinY = Min(Ceiling((Self.mFrameSize.Height - PicSize.Height) / 2), 0)
		    Self.mSourceOffsetMinX = Min(Ceiling((Self.mFrameSize.Width - PicSize.Width) / 2), 0)
		    Self.mSourceOffsetMaxY = Max(Ceiling((PicSize.Height - Self.mFrameSize.Height) / 2), 0)
		    Self.mSourceOffsetMaxX = Max(Ceiling((PicSize.Width - Self.mFrameSize.Width) / 2), 0)
		  #else
		    Self.mSourceOffsetMinY = Min(Ceil((Self.mFrameSize.Height - PicSize.Height) / 2), 0)
		    Self.mSourceOffsetMinX = Min(Ceil((Self.mFrameSize.Width - PicSize.Width) / 2), 0)
		    Self.mSourceOffsetMaxY = Max(Ceil((PicSize.Height - Self.mFrameSize.Height) / 2), 0)
		    Self.mSourceOffsetMaxX = Max(Ceil((PicSize.Width - Self.mFrameSize.Width) / 2), 0)
		  #endif
		  Self.mSourceOffset.X = Max(Min(Self.mSourceOffset.X,Self.mSourceOffsetMaxX),Self.mSourceOffsetMinX)
		  Self.mSourceOffset.Y = Max(Min(Self.mSourceOffset.Y,Self.mSourceOffsetMaxY),Self.mSourceOffsetMinY)
		  
		  Self.Invalidate()
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Attributes( Hidden ) Private Sub StartZoomTimer()
		  If Self.mZoomTimer Is Nil Then
		    Self.mZoomTimer = New Timer
		    AddHandler mZoomTimer.Action, WeakAddressOf ZoomTimerAction
		  End If
		  
		  Self.mZoomTimer.Period = 20
		  Self.mZoomTimer.RunMode = Timer.RunModes.Multiple
		  Self.ZoomTimerAction(Self.mZoomTimer)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Attributes( Hidden ) Private Sub StopZoomTimer()
		  If Self.mZoomTimer <> Nil Then
		    Self.mZoomTimer.RunMode = Timer.RunModes.Off
		  End If
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Update(Source As Picture)
		  If Source Is Nil Then
		    Return
		  End If
		  
		  Self.mSource = Source
		  Self.Invalidate
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Attributes( Hidden ) Private Sub UpdateMetrics()
		  If Self.mSource Is Nil Then
		    Return
		  End If
		  
		  Var AvailableSize As New Xojo.Size(Me.Width - (PaddingSize * 2),Me.Height - ((PaddingSize * 3) + ControllerSize))
		  Self.mFrameSize = Self.FitWithin(Self.mDesiredSize,AvailableSize)
		  Var MinZoomSize As Xojo.Size = Self.FillWithin(New Xojo.Size(Self.mSource.Width,Self.mSource.Height),Self.mDesiredSize)
		  Self.mMinimumZoom = MinZoomSize.Width / Self.mSource.Width
		  Self.mFrameScale = Self.mFrameSize.Width / Self.mDesiredSize.Width
		  
		  Var ControllerWidth As Integer = Max(Min(300,Me.Width - (PaddingSize * 2)),64)
		  Self.mControllerRect = New Xojo.Rect(PaddingSize + (((Me.Width - (PaddingSize * 2)) - ControllerWidth) / 2),Me.Height - (ControllerSize + PaddingSize),ControllerWidth,ControllerSize)
		  Self.mZoomOutButtonRect = New Xojo.Rect(Self.mControllerRect.Left,Self.mControllerRect.Top,ControllerSize,ControllerSize)
		  Self.mZoomInButtonRect = New Xojo.Rect(Self.mControllerRect.Right - ControllerSize,Self.mControllerRect.Top,ControllerSize,ControllerSize)
		  Self.mZoomTrackRect = New Xojo.Rect(Self.mZoomOutButtonRect.Right,Self.mControllerRect.Top,Self.mControllerRect.Width - (ControllerSize * 2),ControllerSize)
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Attributes( Hidden ) Private Sub ZoomTimerAction(Sender As Timer)
		  #pragma Unused Sender
		  
		  Select Case Self.mState
		  Case StateZoomingIn
		    Self.SetZoomLevel(Self.mZoomLevel + 0.01)
		  Case StateZoomingOut
		    Self.SetZoomLevel(Self.mZoomLevel - 0.01)
		  Case StateZoomingTrack
		    If Self.mZoomThumbRect <> Nil And Self.mMousePoint <> Nil Then
		      If Self.mMousePoint.X > Self.mZoomThumbRect.Right Then
		        Self.SetZoomLevel(Self.mZoomLevel + 0.01)
		      ElseIf Self.mMousePoint.X < Self.mZoomThumbRect.Left Then
		        Self.SetZoomLevel(Self.mZoomLevel - 0.01)
		      End If
		    End If
		  End Select
		End Sub
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event SourceImagePresented(SourceImage As Picture)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event SourceImagePresenting(SourceImage As Picture)
	#tag EndHook


	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Self.mBackgroundColor
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Self.mBackgroundColor = Value
			  Self.Invalidate()
			End Set
		#tag EndSetter
		BackgroundColor As Color
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return Self.mHasBackgroundColor
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  If Self.mHasBackgroundColor <> Value Then
			    Self.mHasBackgroundColor = Value
			    Self.Invalidate
			  End If
			End Set
		#tag EndSetter
		HasBackgroundColor As Boolean
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mBackgroundColor As Color
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mControllerRect As Xojo.Rect
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mDesiredSize As Xojo.Size
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mFrameScale As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mFrameSize As Xojo.Size
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mHandleMouseActions As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mHasBackgroundColor As Boolean
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mMinimumZoom As Double
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mMouseDownOffset As Xojo.Point
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mMouseDownPos As Xojo.Point
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mMousePoint As Xojo.Point
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mSource As Picture
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mSourceOffset As Xojo.Point
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mSourceOffsetMaxX As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mSourceOffsetMaxY As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mSourceOffsetMinX As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mSourceOffsetMinY As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mState As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mZoomInButtonRect As Xojo.Rect
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mZoomLevel As Double = 0.5
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mZoomOutButtonRect As Xojo.Rect
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mZoomThumbRect As Xojo.Rect
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mZoomTimer As Timer
	#tag EndProperty

	#tag Property, Flags = &h21
		Attributes( Hidden ) Private mZoomTrackRect As Xojo.Rect
	#tag EndProperty


	#tag Constant, Name = ControllerSize, Type = Double, Dynamic = False, Default = \"16", Scope = Private, Attributes = \"Hidden"
	#tag EndConstant

	#tag Constant, Name = PaddingSize, Type = Double, Dynamic = False, Default = \"5", Scope = Private, Attributes = \"Hidden"
	#tag EndConstant

	#tag Constant, Name = Revision, Type = Double, Dynamic = False, Default = \"2", Scope = Public
	#tag EndConstant

	#tag Constant, Name = StateDraggingPic, Type = Double, Dynamic = False, Default = \"4", Scope = Private, Attributes = \"Hidden"
	#tag EndConstant

	#tag Constant, Name = StateNone, Type = Double, Dynamic = False, Default = \"0", Scope = Private, Attributes = \"Hidden"
	#tag EndConstant

	#tag Constant, Name = StateZoomingIn, Type = Double, Dynamic = False, Default = \"2", Scope = Private, Attributes = \"Hidden"
	#tag EndConstant

	#tag Constant, Name = StateZoomingManually, Type = Double, Dynamic = False, Default = \"3", Scope = Private, Attributes = \"Hidden"
	#tag EndConstant

	#tag Constant, Name = StateZoomingOut, Type = Double, Dynamic = False, Default = \"1", Scope = Private, Attributes = \"Hidden"
	#tag EndConstant

	#tag Constant, Name = StateZoomingTrack, Type = Double, Dynamic = False, Default = \"5", Scope = Private, Attributes = \"Hidden"
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Height"
			Visible=true
			Group="Position"
			InitialValue="100"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue=""
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockBottom"
			Visible=true
			Group="Position"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockLeft"
			Visible=true
			Group="Position"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockRight"
			Visible=true
			Group="Position"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="LockTop"
			Visible=true
			Group="Position"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="TabIndex"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="TabStop"
			Visible=true
			Group="Position"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue=""
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Width"
			Visible=true
			Group="Position"
			InitialValue="100"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="AllowAutoDeactivate"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Tooltip"
			Visible=true
			Group="Appearance"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="AllowFocusRing"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Enabled"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Visible"
			Visible=true
			Group="Appearance"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="AllowFocus"
			Visible=true
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="AllowTabs"
			Visible=true
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="HasBackgroundColor"
			Visible=true
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="BackgroundColor"
			Visible=true
			Group="Behavior"
			InitialValue="&c000000"
			Type="Color"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="DoubleBuffer"
			Visible=true
			Group="Behavior"
			InitialValue="False"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Transparent"
			Visible=true
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Animated"
			Visible=false
			Group="Behavior"
			InitialValue="True"
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Backdrop"
			Visible=false
			Group="Appearance"
			InitialValue=""
			Type="Picture"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="HasFocus"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="InitialParent"
			Visible=false
			Group=""
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="NeedsFullKeyboardAccessForFocus"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="ScrollSpeed"
			Visible=false
			Group="Behavior"
			InitialValue="20"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="TabPanelIndex"
			Visible=false
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
