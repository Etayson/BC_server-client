EnableExplicit
IncludeFile "/libs/Curve64_pub.pb"

Structure settingsStructure 
  rangeB$
  rangeE$
  address$
  isFind.b
  itemsnumber.i
  dp.i
  mapFilename$
  extractFilename$
  totalscanned.i
EndStructure

#ADDRESSSIZE=34
#HEADERSIZE=64+#ADDRESSSIZE+1
#DATASIZE=65

#colorBlue=1
#colorGreen=2
#colorCyan=3
#colorRed=4
#colorMagenta=5
#colorBrown=6
#colorDefault=7
#colorDarkgrey=8
#colorYellow=14
#colorWhite=15
#colorbrightmagenta=13
#colorBrightGreen = 10

Enumeration
  #File
  #ExtractFile
EndEnumeration

#APPVERSION="1.0"

Define NewMap settings.settingsStructure()
Define MutexConsole = CreateMutex()

Procedure SPrint(text$, cl)
 Shared MutexConsole
  LockMutex(MutexConsole)
  ConsoleColor(cl,0)
  Debug FormatDate("%hh:%ii:%ss ", Date())+" "+text$
  PrintN(FormatDate("%hh:%ii:%ss ", Date())+" "+text$)  
  ConsoleColor(#colorDefault,0)
  UnlockMutex(MutexConsole)
EndProcedure

Procedure.s m_cutHex(a$)
  a$=Trim(UCase(a$)) 
  If Left(a$,2)="0X" 
    a$=Mid(a$,3,Len(a$)-2)
  EndIf 
  If Len(a$)=1
    a$="0"+a$
  EndIf
ProcedureReturn LCase(a$)
EndProcedure

Procedure getprogparam()
  Protected parametrscount, err, i,datares$
  Shared  settings()
  parametrscount=CountProgramParameters()
  
  i=0
  While i<parametrscount  
    Select LCase(ProgramParameter(i))
        
      Case "-map"
        Debug "found -map"
        i+1             
        datares$ = ProgramParameter(i)
        If datares$<>"" And Left(datares$,1)<>"-"
          settings("0")\mapFilename$ = datares$
          Sprint( "-map "+settings("0")\mapFilename$,#colordefault)
        EndIf 
      Case "-to"
        Debug "found -to"
        i+1             
        datares$ = ProgramParameter(i)
        If datares$<>"" And Left(datares$,1)<>"-"
          settings("0")\extractFilename$ = datares$
          Sprint( "-to "+settings("0")\extractFilename$,#colordefault)
        EndIf
    EndSelect
    i+1 
  Wend
EndProcedure

Procedure.s m_gethex32(*bin, szbytes)  
  Protected *sertemp=AllocateMemory(szbytes*2, #PB_Memory_NoClear)
  Protected res$  
  ;************************************************************************
  ;Convert bytes in LITTLE indian format to HEX string in BIG indian format
  ;************************************************************************ 
  Curve::m_serializeX64(*bin,0,*sertemp,szbytes/4)  
  res$=PeekS(*sertemp,szbytes*2, #PB_Ascii)
  FreeMemory(*sertemp)
ProcedureReturn res$
EndProcedure

Procedure m_sethex32(*bin, *hash, szbytes)
  Protected a$=PeekS(*hash), i
  ;************************************************************************
  ;Convert HEX string in BIG indian format to bytes in LITTLE indian format
  ;************************************************************************
  a$ = m_cutHex(a$)
  a$=RSet(a$,szbytes*2,"0")  
  Curve::m_deserializeX64(*bin,0,@a$,szbytes/4)  
EndProcedure

Procedure readheader(*set.settingsStructure)
  Protected err=0, i, *MemoryBuffer=AllocateMemory(#HEADERSIZE), procname$ = "[RDH] "
 
  If FileSize(*set\mapFilename$)=-1 
      Sprint(procname$+ "Can`t found "+*set\mapFilename$+" map file", #colorRed)
      err=1
  EndIf
  If Not err
    If ReadFile(#File, *set\mapFilename$,#PB_File_SharedRead)
      ;read header
      ReadData(#File, *MemoryBuffer, #HEADERSIZE)      
      *set\rangeB$ = m_gethex32(*MemoryBuffer, 32)  
      *set\rangeE$ = m_gethex32(*MemoryBuffer+32,32)  
      *set\address$ = PeekS(*MemoryBuffer+64,#ADDRESSSIZE)
      *set\isFind = PeekB(*MemoryBuffer+64+#ADDRESSSIZE)
      *set\itemsnumber = (Lof(#File) -#HEADERSIZE)/#DATASIZE
      i=*set\itemsnumber
      While i>1
        i>>1
        *set\dp+1
      Wend
      
      sprint(procname$+"File           : "+*set\mapFilename$,#colorWhite)
      sprint(procname$+"Range  begin   : "+*set\rangeB$,#colorDarkgrey)
      sprint(procname$+"Range  end     : "+*set\rangeE$,#colorDarkgrey)
      sprint(procname$+"Address        : "+*set\address$,#colorDarkgrey)
      sprint(procname$+"Number of subranges : "+*set\itemsnumber,#colorDarkgrey)
      sprint(procname$+"DP : 2^"+Str(*set\dp),#colorDarkgrey)
      If *set\isFind
        sprint(procname$+"IsFind : True",#colorGreen)
      Else
        sprint(procname$+"IsFind : False",#colorDarkgrey)
      EndIf
      
      If *set\itemsnumber=0
        Sprint(procname$+ "Invalid number of subranges", #colorRed)
        err=1
      EndIf
      If Not err    
        i=0
        While Not Eof(#File)
          ReadData(#File, *MemoryBuffer, #DATASIZE)          
          If PeekB(*MemoryBuffer+64)            
            *set\totalscanned+1          
          EndIf 
          
          i+1
        Wend
        If i<>*set\itemsnumber
          Sprint(procname$+ "Invalid number of subranges> need["+Str(*set\itemsnumber)+"] got ["+Str(i)+"]", #colorRed)
        EndIf
        sprint(procname$+"Total scanned : "+Str(*set\totalscanned),#colorDarkgrey)
      EndIf
      CloseFile(#File)
    Else
      Sprint(procname$+ "Can`t read "+*set\mapFilename$+" map file", #colorRed)
      err=1
    EndIf
  EndIf
  FreeMemory(*MemoryBuffer)
ProcedureReturn err  
EndProcedure

Procedure extract()
  Protected err, procname$ = "[Extractor] ", filepos1, totalscanned, i, a$
  Protected *MemoryBuffer=AllocateMemory(#HEADERSIZE)
  Shared settings()
  
  
  
    If Not OpenFile(#File, settings("0")\mapFilename$)
        Sprint(procname$+ "Can`t found "+settings("0")\mapFilename$+" map file", #colorRed)
        err=1
    EndIf
    If Not err
      If Not CreateFile(#ExtractFile, settings("0")\extractFilename$,#PB_File_SharedRead)
          Sprint(procname$+ "Can`t create "+settings("0")\extractFilename$+" extraction file", #colorRed)
          err=1
      EndIf
      If Not err
        Sprint(procname$+ "Extract already scanned ranges from "+settings("0")\mapFilename$+" to "+settings("0")\extractFilename$, #colorWhite)
        Sprint(procname$+ "Whole range start["+LTrim(settings("0")\rangeB$,"0")+"]", #colorWhite)
        Sprint(procname$+ "Whole range end  ["+LTrim(settings("0")\rangeE$,"0")+"]", #colorWhite)
        Sprint(procname$+ "Address          ["+settings("0")\address$+"]", #colorWhite)
  
        WriteStringN(#ExtractFile,"Whole range start["+LTrim(settings("0")\rangeB$,"0")+"]",#PB_UTF8)
        WriteStringN(#ExtractFile,"Whole range end  ["+LTrim(settings("0")\rangeE$,"0")+"]",#PB_UTF8)
        WriteStringN(#ExtractFile,"Address          ["+settings("0")\address$+"]",#PB_UTF8)
        
        FileSeek(#File, filepos1 * #DATASIZE+ #HEADERSIZE,#PB_Absolute)
        
        While Not Eof(#File) And err=0         
          ReadData(#File, *MemoryBuffer, #DATASIZE)
          
          Debug "rb>"+m_gethex32(*MemoryBuffer, 32) 
          Debug "re>"+m_gethex32(*MemoryBuffer+32,32)
          Debug "iS>"+PeekC(*MemoryBuffer+64)
          If PeekC(*MemoryBuffer+64)
            ;range scanned
            totalscanned+1
            a$=LTrim(m_gethex32(*MemoryBuffer, 32),"0")+":"+LTrim(m_gethex32(*MemoryBuffer+32,32),"0")
            WriteStringN(#ExtractFile,a$,#PB_UTF8)
            Sprint(procname$+ a$, #colorWhite)
          EndIf
          
        Wend
        CloseFile(#File)
        CloseFile(#ExtractFile)
      EndIf
    
    EndIf
    If err      
      DeleteFile(settings("0")\extractFilename$,#PB_FileSystem_Force)
      err=1
    EndIf 
  
  If Not err
    Sprint(procname$+ "Total "+Str(totalscanned)+" scanned subranges extracted to "+settings("0")\extractFilename$, #colorCyan)    
  EndIf
  FreeMemory(*MemoryBuffer)  
ProcedureReturn err    
EndProcedure

OpenConsole()
sprint("app version: "+#APPVERSION,#colorDarkgrey)
Define err

settings("0")\mapFilename$="mmm.bin"
settings("0")\extractFilename$="scannedrange.txt"

getprogparam()  
If Not readheader(@settings("0"))         
  err = extract()  
EndIf   

End
  

; IDE Options = PureBasic 5.31 (Windows - x64)
; ExecutableFormat = Console
; CursorPosition = 215
; FirstLine = 187
; Folding = --
; EnableXP
; Executable = extractor.exe
; CommandLine = mmm.bin mmmmerge.bin mmmsave.bin