#tag Class
Protected Class WebSocketClientTest
Inherits CustomWebSocket
	#tag Event
		Sub Connected()
		  
		  Dim msdiff As Double = ( Me.TimestampConnected.TotalSeconds - Me.TimestampConnecting.TotalSeconds ) * 1000
		  
		  stdout.WriteLine("Connected to [" + Me.Address + ":" + Format(Me.Port, "-#") + "] in [" + Format(msdiff, "-#") + "ms]")
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub Connecting()
		  
		  stdout.WriteLine("Connecting to [" + Me.Address + ":" + Format(Me.Port, "-#") + "]...")
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub Error()
		  
		  stdout.WriteLine("Socket error [#" + Format(Me.LastErrorCode, "-#") + ": " + Me.LastErrorName(True) + "]")
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub HandshakeFinish(httpVersion As String, httpStatusString As String, httpStatusCode As Integer, headers As InternetHeaders)
		  
		  #pragma Unused headers
		  #pragma Unused httpStatusCode
		  
		  If Me.WSEstablished Then
		    stdout.WriteLine("Established WebSocket protocol")
		  Else
		    stdout.WriteLine("Failed to establish the WebSocket protocol: " + httpVersion + " " + httpStatusString)
		  End If
		  
		  If Len(Me.WSProtocol) > 0 Then
		    stdout.WriteLine("Server chose WebSocket protocol [" + Me.WSProtocol + "]")
		  End If
		  
		  Me.Write(New WebSocketMessage("Hello World", WebSocketMessage.OPCODE_TEXT))
		  stdout.WriteLine("<-- Hello World")
		  
		  Me.Write(New WebSocketMessage(ChrB(0) + ChrB(1) + ChrB(2) + ChrB(3), WebSocketMessage.OPCODE_BINARY))
		  stdout.WriteLine("<-- 0x00010203")
		  
		  Me.Write(New WebSocketMessage("", WebSocketMessage.OPCODE_PING))
		  stdout.WriteLine("<-- PING")
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub HandshakeStart()
		  
		  stdout.WriteLine("Starting WebSocket protocol handshake...")
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub MessageAvailable(wsm As WebSocketMessage)
		  
		  Select Case wsm.OperationCode
		  Case wsm.OPCODE_TEXT
		    
		    stdout.WriteLine("--> " + wsm.Payload)
		    
		  Case wsm.OPCODE_BINARY
		    
		    stdout.Write("--> 0x")
		    Dim i, j As Integer
		    i = 1
		    j = LenB(wsm.Payload)
		    While i <= j
		      stdout.Write(Right("0" + Hex(AscB(MidB(wsm.Payload, i, 1))), 2))
		      i = i + 1
		    Wend
		    stdout.WriteLine("")
		    
		  Case wsm.OPCODE_PING
		    
		    stdout.WriteLine("--> PING")
		    Me.Write(New WebSocketMessage(wsm.Payload, WebSocketMessage.OPCODE_PONG))
		    stdout.WriteLine("<-- PONG")
		    
		  Case wsm.OPCODE_PONG
		    
		    stdout.WriteLine("--> PONG")
		    
		  End Select
		  
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h1000
		Sub Constructor()
		  
		  // Calling the overridden superclass constructor.
		  // Note that this may need modifications if there are multiple constructor choices.
		  // Possible constructor calls:
		  // Constructor() -- From TCPSocket
		  // Constructor() -- From SocketCore
		  Super.Constructor()
		  
		  Me.ConnectionType = Me.TLSv1
		  Me.Secure         = True
		  
		End Sub
	#tag EndMethod


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
