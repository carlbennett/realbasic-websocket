#tag Class
Protected Class WebSocketMessage
	#tag Method, Flags = &h0
		Sub Constructor(rawBuffer As String)
		  
		  #pragma DisableBackgroundTasks True
		  
		  Dim buf As New MemoryBlock(LenB(rawBuffer))
		  buf.StringValue(0, buf.Size) = rawBuffer
		  
		  If buf.Size < 2 Then
		    Dim e As New WebSocketException()
		    e.Message = "Insufficient data"
		    Raise e
		  End If
		  
		  buf.LittleEndian = False
		  
		  Dim finalFrame As Boolean = ( BitAnd(buf.UInt8Value(0), &H80) > 0 )
		  Dim reserved1  As Boolean = ( BitAnd(buf.UInt8Value(0), &H40) > 0 )
		  Dim reserved2  As Boolean = ( BitAnd(buf.UInt8Value(0), &H20) > 0 )
		  Dim reserved3  As Boolean = ( BitAnd(buf.UInt8Value(0), &H10) > 0 )
		  Dim opCode     As UInt8   = ( BitAnd(buf.UInt8Value(0), &H0F) )
		  Dim masked     As Boolean = ( BitAnd(buf.UInt8Value(1), &H80) > 0 )
		  Dim msgLen     As UInt64  = ( BitAnd(buf.UInt8Value(1), &H7F) )
		  Dim msgPad     As UInt8   = 2
		  Dim msgRaw     As String
		  
		  If msgLen = 126 Then
		    
		    msgLen = buf.UInt16Value(2)
		    msgPad = 4
		    
		  ElseIf msgLen = 127 Then
		    
		    msgLen = buf.UInt64Value(2)
		    msgPad = 10
		    
		  End If
		  
		  If buf.Size < msgPad + msgLen Then
		    Dim e As New WebSocketException()
		    e.Message = "Insufficient data"
		    Raise e
		  End If
		  
		  msgRaw = buf.StringValue(msgPad, msgLen)
		  
		  buf.Size = msgPad + msgLen
		  
		  #pragma DisableBackgroundTasks False
		  
		  Me.FinalFrame    = finalFrame
		  Me.Masked        = masked
		  Me.OperationCode = opCode
		  Me.Payload       = msgRaw
		  Me.Reserved1     = reserved1
		  Me.Reserved2     = reserved2
		  Me.Reserved3     = reserved3
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(Payload As String, OperationCode As UInt8, Reserved1 As Boolean = False, Reserved2 As Boolean = False, Reserved3 As Boolean = False, Masked As Boolean = False, FinalFrame As Boolean = True)
		  
		  Me.FinalFrame    = FinalFrame
		  Me.Masked        = Masked
		  Me.OperationCode = OperationCode
		  Me.Payload       = Payload
		  Me.Reserved1     = Reserved1
		  Me.Reserved2     = Reserved2
		  Me.Reserved3     = Reserved3
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Operator_Convert() As String
		  
		  If Me.OperationCode < 0 Or Me.OperationCode > 15 Then
		    Dim e As OutOfBoundsException
		    e.Message = "Operation code must be within the range 0-15"
		    Raise e
		  End If
		  
		  Dim msgLen As UInt64 = LenB(Me.Payload)
		  Dim msgPad As UInt8  = 2
		  
		  If msgLen >= 126 And msgLen <= 65535 Then
		    msgPad = 4
		  ElseIf msgLen > 65535 Then
		    msgPad = 10
		  End If
		  
		  Dim buf As New MemoryBlock(msgPad + msgLen)
		  
		  buf.LittleEndian = False
		  
		  If Me.FinalFrame Then buf.UInt8Value(0) = BitOr(buf.UInt8Value(0), &H80)
		  If Me.Reserved1  Then buf.UInt8Value(0) = BitOr(buf.UInt8Value(0), &H40)
		  If Me.Reserved2  Then buf.UInt8Value(0) = BitOr(buf.UInt8Value(0), &H20)
		  If Me.Reserved3  Then buf.UInt8Value(0) = BitOr(buf.UInt8Value(0), &H10)
		  
		  buf.UInt8Value(0) = BitOr(buf.UInt8Value(0), BitAnd(Me.OperationCode, 15))
		  
		  If Me.Masked Then buf.UInt8Value(1) = BitOr(buf.UInt8Value(1), &H80)
		  
		  If msgPad = 2 Then
		    
		    buf.UInt8Value(1) = BitOr(buf.UInt8Value(1), BitAnd(msgLen, &H7F))
		    
		  ElseIf msgPad = 4 Then
		    
		    buf.UInt8Value(1) = BitOr(buf.UInt8Value(1), 126)
		    buf.UInt16Value(2) = msgLen
		    
		  ElseIf msgPad = 10 Then
		    
		    buf.UInt8Value(1) = BitOr(buf.UInt8Value(1), 127)
		    buf.UInt64Value(2) = msgLen
		    
		  End If
		  
		  buf.StringValue(msgPad, buf.Size - msgPad) = Me.payload
		  
		  Return buf
		  
		End Function
	#tag EndMethod


	#tag Property, Flags = &h0
		FinalFrame As Boolean
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  
			  Return LenB(Me)
			  
			End Get
		#tag EndGetter
		Length As UInt64
	#tag EndComputedProperty

	#tag Property, Flags = &h0
		Masked As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		OperationCode As UInt8
	#tag EndProperty

	#tag Property, Flags = &h0
		Payload As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Reserved1 As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		Reserved2 As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		Reserved3 As Boolean
	#tag EndProperty


	#tag Constant, Name = OPCODE_BINARY, Type = Double, Dynamic = False, Default = \"&H02", Scope = Public
	#tag EndConstant

	#tag Constant, Name = OPCODE_CLOSE, Type = Double, Dynamic = False, Default = \"&H08", Scope = Public
	#tag EndConstant

	#tag Constant, Name = OPCODE_CONTINUE, Type = Double, Dynamic = False, Default = \"&H00", Scope = Public
	#tag EndConstant

	#tag Constant, Name = OPCODE_PING, Type = Double, Dynamic = False, Default = \"&H09", Scope = Public
	#tag EndConstant

	#tag Constant, Name = OPCODE_PONG, Type = Double, Dynamic = False, Default = \"&H0A", Scope = Public
	#tag EndConstant

	#tag Constant, Name = OPCODE_TEXT, Type = Double, Dynamic = False, Default = \"&H01", Scope = Public
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InheritedFrom="Object"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			InheritedFrom="Object"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
