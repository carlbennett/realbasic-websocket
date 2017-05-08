#tag Class
Protected Class App
Inherits ConsoleApplication
	#tag Event
		Function Run(args() as String) As Integer
		  
		  #pragma Unused args
		  
		  Me.client = New WebSocketClientTest()
		  
		  Me.client.Address = "127.0.0.1"
		  Me.client.Port    = 8080
		  
		  Me.client.Path    = "/"
		  Me.client.Secure  = False
		  
		  Me.client.Protocols = Array("echo-protocol")
		  
		  Me.client.Connect()
		  
		  Do
		    Me.DoEvents(1)
		    Me.YieldToNextThread()
		  Loop
		  
		  Return 0
		  
		End Function
	#tag EndEvent


	#tag Property, Flags = &h0
		client As WebSocketClientTest
	#tag EndProperty


	#tag ViewBehavior
	#tag EndViewBehavior
End Class
#tag EndClass
