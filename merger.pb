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
  #File2  
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

Procedure.i getprogparam()
  Protected parametrscount, err, i
  Shared  settings()
  parametrscount=CountProgramParameters()
  If parametrscount=3
    i=0
    While i<parametrscount  
      settings(Str(i))\mapFilename$ = ProgramParameter(i)
      i+1
    Wend
  Else
    Sprint("Invalid numbers of params", #colorRed)  
    err=1
  EndIf  
ProcedureReturn err
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

Procedure merge(*init.settingsStructure,*merg.settingsStructure, savefilename$)
  Protected err, procname$ = "[MERGER] ", filepos1, filepos2, newscannedcounter, groupsize, i, step1, step2
  Protected *MemoryBuffer=AllocateMemory(#HEADERSIZE),  *TempBuffer=AllocateMemory(#HEADERSIZE)
  
  groupsize = *init\itemsnumber / *merg\itemsnumber
  Sprint(procname$+ "groupsize = "+Str(groupsize), #colorDefault)
  If CopyFile(*init\mapFilename$, savefilename$)
    If Not OpenFile(#File, savefilename$)
        Sprint(procname$+ "Can`t found "+savefilename$+" map file", #colorRed)
        err=1
    EndIf
    If Not err
      If Not ReadFile(#File2, *merg\mapFilename$,#PB_File_SharedRead)
          Sprint(procname$+ "Can`t found "+*merg\mapFilename$+" map file", #colorRed)
          err=1
      EndIf
      If Not err
        Sprint(procname$+ "Merge "+*merg\mapFilename$+" into "+*init\mapFilename$+"  and save as "+savefilename$, #colorWhite)
        FileSeek(#File2, filepos2 * #DATASIZE+ #HEADERSIZE,#PB_Absolute)
        
        While Not Eof(#File2) And err=0         
          ReadData(#File2, *MemoryBuffer, #DATASIZE)
          
          Debug "rb>"+m_gethex32(*MemoryBuffer, 32) 
          Debug "re>"+m_gethex32(*MemoryBuffer+32,32)
          Debug "iS>"+PeekC(*MemoryBuffer+64)
          If PeekC(*MemoryBuffer+64)
            ;range scanned
            filepos1 = filepos2 *  groupsize
            FileSeek(#File, filepos1 * #DATASIZE+ #HEADERSIZE ,#PB_Absolute)            
            i = 0
            While i<groupsize
              ReadData(#File, *TempBuffer, #DATASIZE)
              Debug "loc>"+Loc(#File)
              Debug "Srb>"+m_gethex32(*TempBuffer, 32) 
              Debug "Sre>"+m_gethex32(*TempBuffer+32,32)
              Debug "SiS>"+PeekC(*TempBuffer+64)
              ;check range
              step1 = Curve::m_check_less_more_equilX64(*TempBuffer,*MemoryBuffer)
              step2 = Curve::m_check_less_more_equilX64(*TempBuffer+32,*MemoryBuffer+32)
              
              If (step1=2 Or step1=0) And (step2=1 Or step2=0)
                ; rb2>=rb and  re2<=re
                If PeekC(*TempBuffer+64)=0
                  ;subrange is not scanned yet
                  ;move write pointer                 
                  FileSeek(#File, -1 ,#PB_Relative)             
                  PokeB(*TempBuffer+64,1)
                  WriteData(#File, *TempBuffer+64, 1)
                 
                  
                  FileSeek(#File, (filepos1 + i+1) * #DATASIZE+ #HEADERSIZE -1 ,#PB_Absolute)                
                  ReadData(#File, *TempBuffer+64, 1)
                  Debug "loc>"+Loc(#File)
                  If PeekC(*TempBuffer+64)=1
                    Debug "OK"
                    newscannedcounter+1
                  Else
                    Debug "SiS>"+PeekC(*TempBuffer+64)
                    Sprint(procname$+ "Can`t save value to map file", #colorRed)
                    err=1
                    Break
                  EndIf
                EndIf
              Else
                Sprint(procname$+ "Hmm. subrange mismatch", #colorRed)
                err=1
                Break
              EndIf
              
              i+1
            Wend
            
          EndIf
          filepos2+1
        Wend
        CloseFile(#File)
        CloseFile(#File2)
      EndIf
    Else
      Sprint(procname$+ "Can`t read "+savefilename$+" map file", #colorRed)      
      err=1
    EndIf
    If err      
      DeleteFile(savefilename$,#PB_FileSystem_Force)
      err=1
    EndIf 
  Else
    Sprint(procname$+ "Can`t copy map file", #colorRed)
    err=1
  EndIf
  If Not err
    Sprint(procname$+ "Merged "+Str(newscannedcounter)+" new subranges", #colorCyan)
    
  EndIf
  FreeMemory(*MemoryBuffer)
  FreeMemory(*TempBuffer)
ProcedureReturn err    
EndProcedure

OpenConsole()
sprint("app version: "+#APPVERSION,#colorDarkgrey)
Define err

settings("0")\mapFilename$="mmm.bin"
settings("1")\mapFilename$="mmmmerge.bin"
settings("2")\mapFilename$="mmmsave.bin"

If Not getprogparam()
  If CompareMemoryString(@settings("2")\mapFilename$, @settings("0")\mapFilename$ ,#PB_String_CaseSensitive)<>#PB_String_Equal And CompareMemoryString(@settings("2")\mapFilename$, @settings("1")\mapFilename$,#PB_String_CaseSensitive)<>#PB_String_Equal
    If CompareMemoryString(@settings("0")\mapFilename$, @settings("1")\mapFilename$ ,#PB_String_CaseSensitive)<>#PB_String_Equal
      If Not readheader(@settings("0"))
        If Not readheader(@settings("1"))
          If CompareMemoryString(@settings("0")\rangeB$, @settings("1")\rangeB$ ,#PB_String_CaseSensitive)=#PB_String_Equal
            If CompareMemoryString(@settings("0")\rangeE$, @settings("1")\rangeE$ ,#PB_String_CaseSensitive)=#PB_String_Equal
              If CompareMemoryString(@settings("0")\address$, @settings("1")\address$ ,#PB_String_CaseSensitive)=#PB_String_Equal
                If settings("0")\isFind=0 And  settings("1")\isFind=0             
                  If settings("0")\itemsnumber>= settings("1")\itemsnumber
                    err = merge(@settings("0"),settings("1"), settings("2")\mapFilename$)
                  Else
                    err = merge(@settings("1"),settings("0"), settings("2")\mapFilename$)
                  EndIf
                  If Not err
                    readheader(@settings("2"))
                  EndIf
                Else
                  Sprint("You already solve key", #colorRed)
                EndIf
              Else
                Sprint("Address mismatch", #colorRed)
              EndIf
            Else
              Sprint("Range  end mismatch", #colorRed)
            EndIf
          Else
            Sprint("Range  begin mismatch", #colorRed)
          EndIf
        EndIf
      EndIf
    Else
      Sprint("Source map can not be equil to merged map", #colorRed)
    EndIf    
  Else
    Sprint("Saved map can not be equil to source or merged map", #colorRed)
  EndIf
EndIf

End
  

; IDE Options = PureBasic 5.31 (Windows - x64)
; ExecutableFormat = Console
; CursorPosition = 37
; FirstLine = 9
; Folding = --
; EnableXP
; Executable = merger.exe
; CommandLine = mmm.bin mmmmerge.bin mmmsave.bin