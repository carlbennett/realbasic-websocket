#tag Class
Protected Class SHA1
	#tag Method, Flags = &h21
		Private Shared Function F1(B as UInt32, C as UInt32, D as UInt32) As UInt32
		  return (B and C) or (not B and D)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function F2(B as UInt32, C as UInt32, D as UInt32) As UInt32
		  return B xor C xor D
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function F3(B as UInt32, C as UInt32, D as UInt32) As UInt32
		  return (B and C) or (B and D) or (C and D)
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function F4(B as UInt32, C as UInt32, D as UInt32) As UInt32
		  return B xor C xor D
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Hash(bs as BinaryStream) As String
		  #pragma disableBackgroundTasks
		  #pragma disableBoundsChecking
		  
		  if bs is nil then
		    return ""
		  end if
		  
		  dim originalEndianValue as Boolean = bs.LittleEndian
		  bs.LittleEndian = false
		  
		  //these are local variables instead of constants so that they will work correctly in integer division
		  //when compiling with versions of REALbasic prior to REALbasic 2008 r2.
		  dim shift1 as UInt32 = &h00000002
		  dim shift2 as Uint32 = &h00000004
		  dim shift5 as UInt32 = &h00000020
		  dim shift27 as UInt32 = &h08000000
		  dim shift30 as UInt32 = &h40000000
		  dim shift31 as UInt32 = &h80000000
		  
		  
		  //some temporary variables.  It turns out that pulling the declaration of W out of the loop
		  //provides a measurable performance boost.
		  dim tmp as UInt32
		  dim X as UInt32
		  dim W(79) as UInt32
		  
		  
		  //the hash is accumulated in these variables.
		  dim H0 as UInt32 = &h67452301
		  dim H1 as UInt32 = &hEFCDAB89
		  dim H2 as UInt32 = &h98BADCFE
		  dim H3 as UInt32 = &h10325476
		  dim H4 as UInt32 = &hC3D2E1F0
		  
		  dim startOfLastBlock as Integer = (bs.Length\BlockSize)*blockSize
		  while bs.Position < startOfLastBlock
		    for t as Integer = 0 to 15
		      W(t) = bs.ReadUInt32
		    next
		    
		    for t as Integer = 16 to 79
		      #if inline
		        X = W(t - 3) xor W(t - 8) xor W(t - 14) xor W(t - 16)
		        W(t) = X*shift1 or X\shift31
		      #else
		        W(t) = S(W(t - 3) xor W(t - 8) xor W(t - 14) xor W(t - 16), 1)
		      #endif
		    next
		    
		    dim A as UInt32 = H0
		    dim B as UInt32 = H1
		    dim C as UInt32 = H2
		    dim D as UInt32 = H3
		    dim E as UInt32 = H4
		    
		    for t as Integer = 0 to 19
		      #if inline
		        tmp = (A*shift5 or A\shift27) + ((B and C) or (not B and D)) + E + W(t) + K1
		      #else
		        tmp = S(A, 5) + F1(B, C, D) + E + W(t) + K1
		      #endif
		      E = D
		      D = C
		      #if inline
		        C = B*shift30 or B\shift2
		      #else
		        C = S(B, 30)
		      #endif
		      B = A
		      A = tmp
		    next
		    for t as Integer = 20 to 39
		      #if inline
		        tmp = (A*shift5 or A\shift27) + (B xor C xor D) + E + W(t) + K2
		      #else
		        tmp = S(A, 5) + F2(B, C, D) + E + W(t) + K2
		      #endif
		      E = D
		      D = C
		      #if inline
		        C = B*shift30 or B\shift2
		      #else
		        C = S(B, 30)
		      #endif
		      B = A
		      A = tmp
		    next
		    for t as Integer = 40 to 59
		      #if inline
		        tmp = (A*shift5 or A\shift27) + ((B and C) or (B and D) or (C and D)) + E + W(t) + K3
		      #else
		        tmp = S(A, 5) + F3(B, C, D) + E + W(t) + K3
		      #endif
		      E = D
		      D = C
		      #if inline
		        C = B*shift30 or B\shift2
		      #else
		        C = S(B, 30)
		      #endif
		      B = A
		      A = tmp
		    next
		    for t as Integer = 60 to 79
		      #if inline
		        tmp = (A*shift5 or A\shift27)+ (B xor C xor D) + E + W(t) + K4
		      #else
		        tmp = S(A, 5) + F4(B, C, D) + E + W(t) + K4
		      #endif
		      E = D
		      D = C
		      #if inline
		        C = B*shift30 or B\shift2
		      #else
		        C = S(B, 30)
		      #endif
		      B = A
		      A = tmp
		    next
		    
		    H0 = H0 + A
		    H1 = H1 + B
		    H2 = H2 + C
		    H3 = H3 + D
		    H4 = H4 + E
		  wend
		  
		  //the last block
		  //SHA-1 requires that the last block be padded out to length 512 bits by appending &b10000000 and the input bit length as a UInt64.
		  //If the length of the last block is > 55 bytes, the result of the padding is that we have two blocks left to process.
		  dim paddedBlockSize as Integer
		  if bs.Length - bs.Position < 56 then
		    paddedBlockSize = blockSize
		  else
		    paddedBlockSize = 2*blockSize
		  end if
		  dim lastBlock as new MemoryBlock(paddedBlockSize)
		  lastBlock.LittleEndian = false
		  dim lastBlockLength as Integer = bs.Length - bs.Position
		  lastBlock.StringValue(0, lastBlockLength) = bs.Read (lastBlockLength)
		  lastBlock.Byte(lastBlockLength) = &b10000000
		  lastBlock.UInt64Value(lastBlock.Size - 8) = bs.Length*8 //length in bits
		  
		  for i as Integer = 0 to lastBlock.Size - 1 step blockSize
		    dim lastBlockOffset as Integer = i
		    for t as Integer = 0 to 15
		      W(t) = lastBlock.UInt32Value(lastBlockOffset)
		      lastBlockOffset = lastBlockOffset + 4
		    next
		    
		    for t as Integer = 16 to 79
		      #if inline
		        X = W(t - 3) xor W(t - 8) xor W(t - 14) xor W(t - 16)
		        W(t) = X*shift1 or X\shift31
		      #else
		        W(t) = S(W(t - 3) xor W(t - 8) xor W(t - 14) xor W(t - 16), 1)
		      #endif
		    next
		    
		    dim A as UInt32 = H0
		    dim B as UInt32 = H1
		    dim C as UInt32 = H2
		    dim D as UInt32 = H3
		    dim E as UInt32 = H4
		    
		    
		    for t as Integer = 0 to 19
		      #if inline
		        tmp = (A*32 or A\shift27) + ((B and C) or (not B and D)) + E + W(t) + K1
		      #else
		        tmp = S(A, 5) + F1(B, C, D) + E + W(t) + K1
		      #endif
		      E = D
		      D = C
		      #if inline
		        C = B*shift30 or B\shift2
		      #else
		        C = S(B, 30)
		      #endif
		      B = A
		      A = tmp
		    next
		    for t as Integer = 20 to 39
		      #if inline
		        tmp = (A*shift5 or A\shift27) + (B xor C xor D) + E + W(t) + K2
		      #else
		        tmp = S(A, 5) + F2(B, C, D) + E + W(t) + K2
		      #endif
		      E = D
		      D = C
		      #if inline
		        C = B*shift30 or B\shift2
		      #else
		        C = S(B, 30)
		      #endif
		      B = A
		      A = tmp
		      
		    next
		    for t as Integer = 40 to 59
		      #if inline
		        tmp = (A*shift5 or A\shift27) + ((B and C) or (B and D) or (C and D)) + E + W(t) + K3
		      #else
		        tmp = S(A, 5) + F3(B, C, D) + E + W(t) + K3
		      #endif
		      E = D
		      D = C
		      #if inline
		        C = B*shift30 or B\shift2
		      #else
		        C = S(B, 30)
		      #endif
		      B = A
		      A = tmp
		    next
		    for t as Integer = 60 to 79
		      #if inline
		        tmp = (A*shift5 or A\shift27)+ (B xor C xor D) + E + W(t) + K4
		      #else
		        tmp = S(A, 5) + F4(B, C, D) + E + W(t) + K4
		      #endif
		      E = D
		      D = C
		      #if inline
		        C = B*shift30 or B\shift2
		      #else
		        C = S(B, 30)
		      #endif
		      B = A
		      A = tmp
		      
		    next
		    H0 = H0 + A
		    H1 = H1 + B
		    H2 = H2 + C
		    H3 = H3 + D
		    H4 = H4 + E
		  next
		  
		  dim theHash as new MemoryBlock(20)
		  theHash.LittleEndian = false
		  theHash.UInt32Value(0) = H0
		  theHash.UInt32Value(4) = H1
		  theHash.UInt32Value(8) = H2
		  theHash.UInt32Value(12) = H3
		  theHash.UInt32Value(16) = H4
		  
		  return theHash
		  
		  
		finally
		  bs.LittleEndian = originalEndianValue
		  
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Hash(f as FolderItem) As String
		  if f is nil then
		    return ""
		  end if
		  if f.Directory then
		    return ""
		  end if
		  
		  return Hash(BinaryStream.Open(f))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function Hash(s as String) As String
		  return Hash(new BinaryStream(s))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function HMAC(key as String, msg as String) As String
		  if LenB(key) > BlockSize then
		    key = Hash(key)
		  end if
		  key = LeftB(key + Pad(Chr(0), BlockSize), BlockSize)
		  dim keyStream as new BinaryStream(key)
		  
		  dim ipad as new MemoryBlock(BlockSize)
		  dim opad as new MemoryBlock(BlockSize)
		  
		  dim offset as Integer = 0
		  while keyStream.Position < keyStream.Length
		    dim keyByte as UInt8 = keyStream.ReadUInt8
		    ipad.UInt8Value(offset) = keyByte xor &h36
		    opad.UInt8Value(offset) = keyByte xor &h5c
		    offset = offset + 1
		  wend
		  
		  return Hash(opad + Hash(ipad + msg))
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function Pad(s as String, byteLength as Integer) As String
		  dim pad as String = s
		  while LenB(pad) < byteLength
		    pad = pad + pad
		  wend
		  return LeftB(pad, byteLength)
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Shared Function S(X as Uint32, N as Integer) As UInt32
		  //circular shift of X by N positions to the left
		  
		  return Bitwise.ShiftLeft(X, N) or Bitwise.ShiftRight(X, 32 - N)
		End Function
	#tag EndMethod


	#tag Note, Name = Read Me
		SHA1 9/20/2008
		
		SHA1 contains an implementation of the SHA-1 hash algorithm as described in FIPS 180-1: Secure Hash Standard
		<http://www.itl.nist.gov/fipspubs/fip180-1.htm>.
		
		The class requires REALbasic 2007r2 or newer, thanks to the use of the xor operator.  Probably it could be made to run in earlier versions of REALbasic,
		though I won't be doing it.
		
		
		--------
		
		Class Interface
		
		
		SHA1.Hash is overloaded to accept a FolderItem, BinaryStream, or String as input.  If you want to hash the contents of a MemoryBlock, you
		could either wrap it in a BinaryStream (see the BinaryStream documentation) or copy it to a String.
		
		SHA1.HMAC computes a hash message authentication code using SHA1.
		
		
		--------
		
		
		Change Notes
		
		9/20/2008 Bit shift constants have been replaced by local variables to better express my intent to the compiler in REALbasic versions prior to REALbasic 2008r2. 
		Thanks to Didier Barbas and Patrick van der Perre for spotting and reporting the problems.
		
		9/19/2008 This release fixes a bug in the code that finished the hash computation.  More test computations have been added, and I've added an HMAC function.
		
		
		
		e-mail: charles@declareSub.com
		web: http://www.declareSub.com
	#tag EndNote


	#tag Constant, Name = BlockSize, Type = Double, Dynamic = False, Default = \"64", Scope = Private
	#tag EndConstant

	#tag Constant, Name = inline, Type = Boolean, Dynamic = False, Default = \"true", Scope = Private
	#tag EndConstant

	#tag Constant, Name = K1, Type = Double, Dynamic = False, Default = \"&h5A827999", Scope = Private
	#tag EndConstant

	#tag Constant, Name = K2, Type = Double, Dynamic = False, Default = \"&h6ED9EBA1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = K3, Type = Double, Dynamic = False, Default = \"&h8F1BBCDC", Scope = Private
	#tag EndConstant

	#tag Constant, Name = K4, Type = Double, Dynamic = False, Default = \"&hCA62C1D6", Scope = Private
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="2147483648"
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
