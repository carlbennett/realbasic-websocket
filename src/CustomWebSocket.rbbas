#tag Class
Protected Class CustomWebSocket
Inherits SSLSocket
	#tag Event
		Sub Connected()
		  
		  Me.ConnectedTimestamp = New Date()
		  Me.DataBuffer         = ""
		  Me.WSClientKey        = Me.GetClientKey()
		  Me.WSEstablishedVal   = False
		  Me.WSKeyExchange      = False
		  Me.WSProtocolVal      = ""
		  Me.WSServerKey        = ""
		  
		  Connected()
		  
		  Me.Write(Me.CreateRequest())
		  
		  HandshakeStart()
		  
		End Sub
	#tag EndEvent

	#tag Event
		Sub DataAvailable()
		  
		  Me.DataBuffer = Me.DataBuffer + Me.ReadAll()
		  
		  If Me.WSEstablishedVal Then
		    Dim wsm As WebSocketMessage
		    Do
		      Try
		        If LenB(Me.DataBuffer) = 0 Then Exit Do
		        wsm = New WebSocketMessage(Me.DataBuffer)
		        Me.DataBuffer = MidB(Me.DataBuffer, 1 + wsm.Length)
		        MessageAvailable(wsm)
		      Catch error As WebSocketException
		        If error.Message <> "Insufficient data" Then Raise error Else Exit Do
		      End Try
		    Loop
		    Return
		  End If
		  
		  Dim linesUbound As Integer
		  Dim lines() As String = Split(ReplaceLineEndings(Me.DataBuffer, EndOfLine), EndOfLine)
		  Dim line, headerKey, headerVal As String
		  
		  linesUbound = lines.Ubound
		  
		  Dim uri As String
		  Dim headers As InternetHeaders
		  
		  Do
		    
		    uri = lines(0)
		    lines.Remove(0)
		    
		    headers = New InternetHeaders()
		    
		    Do Until lines.Ubound < 1 Or LenB(lines(0)) = 0
		      line = lines(0)
		      headerKey = Trim(NthField(line, ":", 1))
		      headerVal = Trim(Mid(line, Len(headerKey) + 2))
		      headers.AppendHeader(headerKey, headerVal)
		      lines.Remove(0)
		    Loop
		    
		    If lines.Ubound < 1 Or LenB(lines(0)) <> 0 Then
		      // Incomplete response, wait for more data
		      Return
		    End If
		    
		    lines.Remove(0)
		    
		    Me.DataBuffer = Join(lines, EndOfLine)
		    
		    Me.HandleResponse(uri, headers)
		    
		  Loop
		  
		End Sub
	#tag EndEvent


	#tag Method, Flags = &h0
		Sub Connect()
		  
		  If Me.IsConnected = True Then
		    Me.Disconnect()
		  Else
		    Me.Close()
		  End If
		  
		  Me.ConnectingTimestamp = New Date()
		  
		  Connecting()
		  
		  Me.OriginalPort = Me.Port
		  
		  Super.Connect()
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function CreateRequest() As String
		  
		  Dim buf As String = ""
		  
		  buf = buf + "GET " + Me.Path + " HTTP/1.0" + EndOfLine.UNIX + _
		  "Host: " + Me.Address + ":" + Format(Me.OriginalPort, "-#") + EndOfLine.UNIX + _
		  "Upgrade: WebSocket" + EndOfLine.UNIX + _
		  "Connection: Upgrade" + EndOfLine.UNIX + _
		  "Sec-WebSocket-Version: 13" + EndOfLine.UNIX + _
		  "Sec-WebSocket-Key: " + EncodeBase64(Me.WSClientKey) + EndOfLine.UNIX
		  
		  If Me.Protocols.Ubound >= 0 Then
		    buf = buf + "Sec-WebSocket-Protocol: " + Join(Me.Protocols, ",") + EndOfLine.UNIX
		  End If
		  
		  If Me.Extensions.Ubound >= 0 Then
		    buf = buf + "Sec-WebSocket-Extensions: " + Join(Me.Extensions, ",") + EndOfLine.UNIX
		  End If
		  
		  Return buf + EndOfLine.UNIX
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function GetClientKey() As String
		  
		  Dim buf As String
		  
		  While Len(buf) < Me.WS_RFC6455_CLIENT_KEY_LEN
		    buf = buf + ChrB(Floor(Rnd() * 256))
		  Wend
		  
		  Return buf
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h1
		Protected Function GetHeader(headers As InternetHeaders, key As String, notFound As String = "") As String
		  
		  Dim i As Integer = headers.Count()
		  Dim buf As String = ""
		  Dim nf As Boolean = True
		  
		  While i > 0
		    i = i - 1
		    If headers.Name(i) = key Then
		      nf = False
		      If Len(buf) > 0 Then buf = buf + ","
		      buf = buf + headers.Value(i)
		    End If
		  Wend
		  
		  If nf Then Return notFound Else Return buf
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub HandleResponse(uri As String, headers As InternetHeaders)
		  
		  Dim httpVersion      As String  = NthField( uri, " ", 1 )
		  Dim httpStatusString As String  = Mid( uri, Len( httpVersion ) + 2 )
		  Dim httpStatusCode   As Integer = Val( NthField( httpStatusString, " ", 1 ) )
		  
		  Me.WSEstablishedVal = (httpStatusCode = 101)
		  Me.WSProtocolVal    = Me.GetHeader(headers, "Sec-WebSocket-Protocol")
		  Me.WSServerKey      = DecodeBase64(Me.GetHeader(headers, "Sec-WebSocket-Accept"))
		  
		  If Len(Me.WSServerKey) > 0 Then
		    
		    Dim checksum As String = SHA1.Hash(EncodeBase64(Me.WSClientKey) + Me.WS_RFC6455_GUID_Key)
		    
		    Me.WSKeyExchange = (Me.WSServerKey = checksum)
		    
		  Else
		    Me.WSKeyExchange = False
		  End If
		  
		  If Not Me.WSKeyExchange Then
		    Me.WSEstablishedVal = False // RFC 6455
		  End If
		  
		  Me.WSExtensionsVal = Me.GetHeader(headers, "Sec-WebSocket-Extensions")
		  
		  If Me.WSVerifyProtocol() Then
		    Call Me.WSVerifyExtensions()
		  End If
		  
		  HandshakeFinish(httpVersion, httpStatusString, httpStatusCode, headers)
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function LastErrorName(friendlyNames As Boolean) As String
		  
		  Dim code As Integer = Me.LastErrorCode
		  
		  Select Case code
		  Case Me.NoError
		    If friendlyNames Then Return "No error" Else Return "NoError"
		    
		  Case Me.OpenDriverError
		    If friendlyNames Then Return "Open driver error" Else Return "OpenDriverError"
		    
		  Case Me.LostConnection
		    If friendlyNames Then Return "Lost connection" Else Return "LostConnection"
		    
		  Case Me.NameResolutionError
		    If friendlyNames Then Return "Name resolution error" Else Return "NameResolutionError"
		    
		  Case Me.AddressInUseError
		    If friendlyNames Then Return "Address in use error" Else Return "AddressInUseError"
		    
		  Case Me.InvalidStateError
		    If friendlyNames Then Return "Invalid state error" Else Return "InvalidStateError"
		    
		  Case Me.InvalidPortError
		    If friendlyNames Then Return "Invalid port error" Else Return "InvalidPortError"
		    
		  Case Else
		    If friendlyNames Then Return "Unknown error (" + Format(code, "-#") + ")" Else Return "UnknownError(" + Format(code, "-#") + ")"
		    
		  End Select
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function WSVerifyExtensions() As Boolean
		  
		  Dim values() As String = Split(Me.WSExtensionsVal, ",")
		  Dim i, j, k As Integer
		  
		  i = Me.Extensions.Ubound
		  j = values.Ubound
		  
		  While i >= 0
		    k = j
		    While j >= 0
		      If values(i) = Me.Extensions(j) Then
		        k = k - 1
		      End If
		      j = j - 1
		    Wend
		    If j < k Then Return False
		    i = i - 1
		  Wend
		  
		  Return True
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Function WSVerifyProtocol() As Boolean
		  
		  Dim j As Integer = Me.Protocols.Ubound
		  
		  For i As Integer = 0 To j
		    If Me.Protocols(i) = Me.WSProtocolVal Then Return True
		  Next
		  
		  Return False
		  
		End Function
	#tag EndMethod


	#tag Hook, Flags = &h0
		Event Connected()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event Connecting()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event HandshakeFinish(httpVersion As String, httpStatusString As String, httpStatusCode As Integer, headers As InternetHeaders)
	#tag EndHook

	#tag Hook, Flags = &h0
		Event HandshakeStart()
	#tag EndHook

	#tag Hook, Flags = &h0
		Event MessageAvailable(wsm As WebSocketMessage)
	#tag EndHook


	#tag Property, Flags = &h1
		Protected ConnectedTimestamp As Date
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected ConnectingTimestamp As Date
	#tag EndProperty

	#tag Property, Flags = &h21
		Private DataBuffer As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Extensions() As String
	#tag EndProperty

	#tag Property, Flags = &h1
		Protected OriginalPort As Integer
	#tag EndProperty

	#tag Property, Flags = &h0
		Path As String
	#tag EndProperty

	#tag Property, Flags = &h0
		Protocols() As String
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  
			  Return Me.ConnectedTimestamp
			  
			End Get
		#tag EndGetter
		TimestampConnected As Date
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  
			  Return Me.ConnectingTimestamp
			  
			End Get
		#tag EndGetter
		TimestampConnecting As Date
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private WSClientKey As String
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  
			  Return Me.WSEstablishedVal
			  
			End Get
		#tag EndGetter
		WSEstablished As Boolean
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private WSEstablishedVal As Boolean
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  
			  Return Me.WSExtensionsVal
			  
			End Get
		#tag EndGetter
		WSExtensions As String
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private WSExtensionsVal As String
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  
			  Return Me.WSKeyExchange
			  
			End Get
		#tag EndGetter
		WSHandshake As Boolean
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private WSKeyExchange As Boolean
	#tag EndProperty

	#tag Property, Flags = &h0
		WSMessage As WebSocketMessage
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  
			  Return Me.WSProtocolVal
			  
			End Get
		#tag EndGetter
		WSProtocol As String
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private WSProtocolVal As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private WSServerKey As String
	#tag EndProperty


	#tag Constant, Name = WS_RFC6455_CLIENT_KEY_LEN, Type = Double, Dynamic = False, Default = \"16", Scope = Private
	#tag EndConstant

	#tag Constant, Name = WS_RFC6455_GUID_Key, Type = String, Dynamic = False, Default = \"258EAFA5-E914-47DA-95CA-C5AB0DC85B11", Scope = Private
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="CertificateFile"
			Visible=true
			Group="Behavior"
			Type="FolderItem"
			InheritedFrom="SSLSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="CertificatePassword"
			Visible=true
			Group="Behavior"
			Type="String"
			InheritedFrom="SSLSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="CertificateRejectionFile"
			Visible=true
			Group="Behavior"
			Type="FolderItem"
			InheritedFrom="SSLSocket"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ConnectionType"
			Visible=true
			Group="Behavior"
			InitialValue="2"
			Type="Integer"
			InheritedFrom="SSLSocket"
		#tag EndViewProperty
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
			Name="Path"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Secure"
			Visible=true
			Group="Behavior"
			Type="Boolean"
			InheritedFrom="SSLSocket"
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
		#tag ViewProperty
			Name="WSEstablished"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="WSExtensions"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="WSHandshake"
			Group="Behavior"
			Type="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="WSProtocol"
			Group="Behavior"
			Type="String"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
