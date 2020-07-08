EnableExplicit
IncludeFile "/libs/Curve64_pub.pb"


Structure settingsStructure
  port.i  
  host.s
  hash$
  rangeB$
  rangeE$
  address$  
  powaddress$
  outFilename$ 
  Progname.s
  name.s
  pass.s
  device$
  thread$
  blocks$
  points$
EndStructure

Structure CrackStructure
  isok.b
  Compiler.i
  isRunning.i
  killapp.b
EndStructure

Structure checkjobStructure
  err.i
  isRunning.i 
  hash$
  timestamp.i
EndStructure

Enumeration
#File
EndEnumeration

Enumeration
#sendgetjob_id
#login_id
#sendkey_id
#checkjob_id
EndEnumeration


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

#ADDRESSSIZE=34
#HEADERSIZE=64+#ADDRESSSIZE+1
#DATASIZE=65

#CHECKJOBTIME=60
#APPVERSION="1.0"

Define MutexConsole = CreateMutex()
Define NewMap settings.settingsStructure()
Define *rangeB,*rangeE, isFind=#False


Define *CurveP, *CurveGX, *CurveGY, *Curveqn
*CurveP = Curve::m_getCurveValues()
*CurveGX = *CurveP+32
*CurveGY = *CurveP+64
*Curveqn = *CurveP+96

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

Procedure.s getElem(js.i,pname.s="",pelem.l=0,aelem.l=0)
  Protected result$,jsFloat_g
  
  result$=""
  If IsJSON(js) And GetJSONMember(JSONValue(js), pname)
    Select JSONType(GetJSONMember(JSONValue(js), pname))
      
      Case #PB_JSON_String
        result$= GetJSONString(GetJSONMember(JSONValue(js), pname))  
        
      Case #PB_JSON_Array          
       If JSONArraySize(GetJSONMember(JSONValue(js), pname))>pelem
         Select JSONType(GetJSONElement(GetJSONMember(JSONValue(js), pname), pelem))
           Case #PB_JSON_String
             result$= GetJSONString(GetJSONElement(GetJSONMember(JSONValue(js), pname), pelem))
             
           Case #PB_JSON_Number            
             result$= Str(GetJSONInteger(GetJSONElement(GetJSONMember(JSONValue(js), pname), pelem)))    
             jsFloat_g=GetJSONDouble(GetJSONElement(GetJSONMember(JSONValue(js), pname), pelem))
             
           Case #PB_JSON_Array
             If JSONArraySize(GetJSONElement(GetJSONMember(JSONValue(js), pname), pelem))>aelem             
                result$+ GetJSONString(GetJSONElement(GetJSONElement(GetJSONMember(JSONValue(js), pname), pelem),aelem))
             EndIf
          Case #PB_JSON_Boolean
             result$=Str(GetJSONBoolean(GetJSONElement(GetJSONMember(JSONValue(js), pname), pelem)))
             
         EndSelect          
        EndIf
        
      Case #PB_JSON_Boolean
        result$=Str(GetJSONBoolean(GetJSONMember(JSONValue(js), pname)))        
        
      Case #PB_JSON_Number        
        result$= Str(GetJSONInteger(GetJSONMember(JSONValue(js), pname)))
        
    EndSelect  
  EndIf
  ProcedureReturn result$
EndProcedure

Procedure.s getprogparam()
  Protected parametrscount, datares$, i, params$
  Shared  settings()
  parametrscount=CountProgramParameters()
  
  i=0
  While i<parametrscount  
    Select LCase(ProgramParameter(i))
        
      Case "-prog"
        Debug "found -prog"
        i+1             
        datares$ = ProgramParameter(i)
        If datares$<>"" And Left(datares$,1)<>"-"
          settings("1")\Progname = StringField(datares$,1,".") +".exe"         
          Sprint( "-prog "+settings("1")\Progname,#colordefault)
        EndIf 
      Case "-name"
        Debug "found -name"
        i+1             
        datares$ = ProgramParameter(i)
        If datares$<>"" And Left(datares$,1)<>"-"
          settings("1")\name = datares$         
          Sprint( "-name "+settings("1")\name,#colordefault)
        EndIf
      Case "-pass"
        Debug "found -pass"
        i+1             
        datares$ = ProgramParameter(i)
        If datares$<>"" And Left(datares$,1)<>"-"
          settings("1")\pass = datares$         
          Sprint( "-pass "+settings("1")\pass,#colordefault)
        EndIf
       Case "-pool"
        Debug "found -pool"
        
        i+1  
        datares$ = ProgramParameter(i)         
        If datares$<>"" And Left(datares$,1)<>"-"
          If GetURLPart(datares$, #PB_URL_Protocol)=""
             datares$="http://"+datares$
          EndIf          
          settings("1")\host =GetURLPart(datares$, #PB_URL_Site)
          settings("1")\port = Val(GetURLPart(datares$, #PB_URL_Port))
          Sprint( "-pool "+settings("1")\host+":"+settings("1")\port,#colordefault)
        EndIf
       Case "-d"
        Debug "found -d"
        i+1             
        datares$ = ProgramParameter(i)
        If datares$<>"" And Left(datares$,1)<>"-"
          settings("1")\device$ = Str(Val(datares$))
          Sprint( "-d "+settings("1")\device$,#colordefault)
        EndIf 
       Case "-t"
        Debug "found -t"
        i+1             
        datares$ = ProgramParameter(i)
        If datares$<>"" And Left(datares$,1)<>"-"
          settings("1")\thread$ = datares$         
          Sprint( "-t "+settings("1")\thread$,#colordefault)
        EndIf
       Case "-b"
        Debug "found -b"
        i+1             
        datares$ = ProgramParameter(i)
        If datares$<>"" And Left(datares$,1)<>"-"
          settings("1")\blocks$ = datares$         
          Sprint( "-b "+settings("1")\blocks$,#colordefault)
        EndIf 
       Case "-p"
        Debug "found -p"
        i+1             
        datares$ = ProgramParameter(i)
        If datares$<>"" And Left(datares$,1)<>"-"
          settings("1")\points$ = datares$         
          Sprint( "-p "+settings("1")\points$,#colordefault)
        EndIf
    EndSelect
    i+1 
  Wend
  
  Debug "all params["+params$+"]"
ProcedureReturn params$
EndProcedure

Procedure.s m_gethex32(*bin, szbytes)  
  Protected *sertemp=AllocateMemory(szbytes*2, #PB_Memory_NoClear)
  Protected res$  
  ;************************************************************************
  ;Convert bytes to HEX string 
  ;************************************************************************ 
  Curve::m_serializeX64(*bin,0,*sertemp,szbytes/4)  
  res$=PeekS(*sertemp,szbytes*2, #PB_Ascii)
  FreeMemory(*sertemp)
ProcedureReturn res$
EndProcedure

Procedure m_sethex32(*bin, *hash, szbytes)
  Protected a$=PeekS(*hash), i
  ;************************************************************************
  ;Convert HEX string to bytes
  ;************************************************************************
  a$ = m_cutHex(a$)
  a$=RSet(a$,szbytes*2,"0")  
  Curve::m_deserializeX64(*bin,0,@a$,szbytes/4)  
EndProcedure

Procedure.i SendQuestion(con_id,string$)
  Protected err
  If con_id
    SendNetworkString(con_id,string$+#LF$,#PB_Ascii)
  EndIf
ProcedureReturn err
EndProcedure

Procedure GetJobHost()
  Protected totalloadbytes, maxloadbytes, loadedbytes, *pp, i, err, batchCRC32, get_work_getjob_string.s, quit=#False,  timeout
  Protected Connect, dis=1, pars_res, *Buffer, ReceivedBytes, answer_t$, pos, pos2, answer_f$, tempjson, get_work, Values, get_work_authorize_string.s, id_json_answer,msginit$, isAuthorized
  Shared settings() 
  
  *Buffer = AllocateMemory(65536)
  msginit$ ="[GETWORK_GJ] "
  tempjson = CreateJSON(#PB_Any)
  If tempjson   
    get_work = SetJSONObject(JSONValue(tempjson))   
    SetJSONInteger(AddJSONMember(get_work, "id"), #login_id) 
    SetJSONString(AddJSONMember(get_work, "method"), "Login")
    Values =SetJSONArray(AddJSONMember(get_work, "params"))      
    SetJSONString(AddJSONElement(Values), settings("1")\name)     
    SetJSONString(AddJSONElement(Values), settings("1")\pass)
    get_work_authorize_string=ComposeJSON(tempjson)
    FreeJSON(tempjson)
  EndIf
  
  tempjson = CreateJSON(#PB_Any)
    If tempjson   
      get_work = SetJSONObject(JSONValue(tempjson))   
      SetJSONInteger(AddJSONMember(get_work, "id"), #sendgetjob_id) 
      SetJSONString(AddJSONMember(get_work, "method"), "getwork")
      get_work_getjob_string=ComposeJSON(tempjson)
      FreeJSON(tempjson)
    EndIf
    
  Repeat
    If dis=1
      isAuthorized =#False      
      Connect = OpenNetworkConnection(settings("1")\host ,settings("1")\port,#PB_Network_TCP,10000)
      If Not Connect
        
        While Not Connect And timeout<5
          timeout+1
          Debug "try conect to getwork"
          Delay(1000)
          Connect = OpenNetworkConnection(settings("1")\host ,settings("1")\port,#PB_Network_TCP,10000)
        Wend
        If Not Connect
          ;cant` connect
           Connect = 0
            err=2
            quit = #True
            Break
        EndIf
      EndIf   
      dis=0
      SendQuestion(Connect,get_work_authorize_string) 
      
    EndIf
  
  If Connect
    Select NetworkClientEvent(Connect) 
        Case #PB_NetworkEvent_Data     
        ReceivedBytes = ReceiveNetworkData(Connect, *Buffer, 65536) 
        If ReceivedBytes>0
          answer_t$=PeekS(*Buffer, ReceivedBytes,#PB_Ascii)  
          Debug answer_t$
          pos=FindString(answer_t$, "{")
          While pos                
            pos2=FindString(answer_t$, "}",pos+1)
            If pos2            
              answer_f$=Mid(answer_t$,pos,pos2-pos+1)            
              answer_f$ = RTrim(answer_f$,"}")
              answer_f$ = LTrim(answer_f$,"{")                   
              answer_f$ = "{"+answer_f$+"}"
              Debug">>"+answer_f$        
              pars_res=ParseJSON(#PB_Any, answer_f$)                    
              If pars_res
                id_json_answer=Val(LCase(m_cutHex(getElem(pars_res,"id",0))))
                If id_json_answer
                  Select id_json_answer 
                    Case #login_id
                      If Not Val(getElem(pars_res,"result",0))
                        If LCase(getElem(pars_res,"error",0))="invalid_login"
                          Sprint(msginit$+">>Invalid Login<<",#colorRed)
                          Delay(1000)
                          dis=1
                          isAuthorized =#False
                        ElseIf LCase(getElem(pars_res,"error",0))="keyfounded"
                          err=3
                          quit = #True
                          Break
                        EndIf
                      Else
                        Sprint(msginit$+"Authorized", #colorBrown)  
                        isAuthorized =#True
                        SendQuestion(Connect,get_work_getjob_string)
                        
                        
                      EndIf
                  EndSelect
                Else                 
                      Debug"*****"
                      If getElem(pars_res,"error",0)=""
                        Sprint(msginit$+">>Got Job from host<<",#colorBrown)
                        settings("1")\hash$ = getElem(pars_res,"result",0)
                        settings("1")\rangeB$ = getElem(pars_res,"result",1)
                        settings("1")\rangeE$ = getElem(pars_res,"result",2)
                        settings("1")\address$ = getElem(pars_res,"result",3)
                        settings("1")\powaddress$ = getElem(pars_res,"result",4)
                        Sprint(msginit$+"HASH    ["+settings("1")\hash$+"]",#colorBrown)
                        Sprint(msginit$+"RANGEB  ["+settings("1")\rangeB$+"]",#colorBrown)
                        Sprint(msginit$+"RANGEE  ["+settings("1")\rangeE$+"]",#colorBrown)
                        Sprint(msginit$+"ADDRESS ["+settings("1")\address$+"]",#colorBrown)     
                        Sprint(msginit$+"POW ADDR["+settings("1")\powaddress$+"]",#colorBrown)
                        quit = #True
                        Break
                      Else
                        Sprint(msginit$+getElem(pars_res,"error",0), #colorRed)
                        If LCase(getElem(pars_res,"error",0))="keyfounded"
                          err=3
                          quit = #True
                          Break
                        ElseIf LCase(getElem(pars_res,"error",0))="range_scanned"
                          err=4
                          quit = #True
                          Break
                        Else
                          err=5
                          quit = #True
                          Break
                        EndIf
                        
                      EndIf
                EndIf
                If IsJSON(pars_res)
                  FreeJSON(pars_res)
                EndIf 
              Else
                    Sprint(msginit$+" unknown json",#colorred)
              EndIf
              answer_t$= Right(answer_t$, Len(answer_t$)-pos2)
              pos=FindString(answer_t$, "{")
            Else
              pos=0
            EndIf
          Wend
        EndIf
        
      Case #PB_NetworkEvent_Disconnect
        Debug "getwork disconnected"
        Connect = 0
        err=1
        quit = #True
    EndSelect
    
    
  EndIf
  Delay (1)
Until quit
If Connect
  CloseNetworkConnection(Connect)
EndIf
FreeMemory(*Buffer)
ProcedureReturn err  
EndProcedure

Procedure CheckJobHost(*checkjob.checkjobStructure)
  Protected totalloadbytes, maxloadbytes, loadedbytes, *pp, i, err, batchCRC32, get_work_checkwork_string.s, quit=#False,  timeout
  Protected Connect, dis=1, pars_res, *Buffer, ReceivedBytes, answer_t$, pos, pos2, answer_f$, tempjson, get_work, Values, get_work_authorize_string.s, id_json_answer,msginit$, isAuthorized
  Protected sendtime.i
  Shared settings()
  *Buffer = AllocateMemory(65536)
  msginit$ ="[GETWORK_CJ] "
  
  tempjson = CreateJSON(#PB_Any)
  If tempjson   
    get_work = SetJSONObject(JSONValue(tempjson))   
    SetJSONInteger(AddJSONMember(get_work, "id"), #login_id) 
    SetJSONString(AddJSONMember(get_work, "method"), "Login")
    Values =SetJSONArray(AddJSONMember(get_work, "params"))      
    SetJSONString(AddJSONElement(Values), settings("1")\name)     
    SetJSONString(AddJSONElement(Values), settings("1")\pass)
    get_work_authorize_string=ComposeJSON(tempjson)
    FreeJSON(tempjson)
  EndIf
  
  tempjson = CreateJSON(#PB_Any)
    If tempjson   
      get_work = SetJSONObject(JSONValue(tempjson))   
      SetJSONInteger(AddJSONMember(get_work, "id"), #checkjob_id) 
      SetJSONString(AddJSONMember(get_work, "method"), "checkjob")
      Values =SetJSONArray(AddJSONMember(get_work, "params"))         
      SetJSONString(AddJSONElement(Values), *checkjob\hash$)
      get_work_checkwork_string=ComposeJSON(tempjson)
      FreeJSON(tempjson)
    EndIf
  
  Repeat
    If dis=1
      isAuthorized =#False    
      Connect = OpenNetworkConnection(settings("1")\host ,settings("1")\port,#PB_Network_TCP,10000)
      If Not Connect
        
        While Not Connect And timeout<5
          timeout+1
          Debug "try conect to getwork"
          Delay(1000)
          Connect = OpenNetworkConnection(settings("1")\host ,settings("1")\port,#PB_Network_TCP,10000)
        Wend
        If Not Connect
          ;cant` connect
           Connect = 0
            err=2
            quit = #True
            Break
        EndIf
      EndIf   
      dis=0
      SendQuestion(Connect,get_work_authorize_string) 
      sendtime = Date()
    EndIf
  
  If Connect
    Select NetworkClientEvent(Connect) 
        Case #PB_NetworkEvent_Data     
        ReceivedBytes = ReceiveNetworkData(Connect, *Buffer, 65536) 
        If ReceivedBytes>0
          answer_t$=PeekS(*Buffer, ReceivedBytes,#PB_Ascii)  
          Debug answer_t$
          pos=FindString(answer_t$, "{")
          While pos                
            pos2=FindString(answer_t$, "}",pos+1)
            If pos2            
              answer_f$=Mid(answer_t$,pos,pos2-pos+1)            
              answer_f$ = RTrim(answer_f$,"}")
              answer_f$ = LTrim(answer_f$,"{")                   
              answer_f$ = "{"+answer_f$+"}"
              Debug">>"+answer_f$        
              pars_res=ParseJSON(#PB_Any, answer_f$)                    
              If pars_res
                id_json_answer=Val(LCase(m_cutHex(getElem(pars_res,"id",0))))
                If id_json_answer
                  Select id_json_answer                            
                    Case #login_id
                      If Not Val(getElem(pars_res,"result",0))
                        If LCase(getElem(pars_res,"error",0))="invalid_login"
                          Sprint(msginit$+">>Invalid Login<<",#colorRed)
                          Delay(1000)
                          dis=1
                          isAuthorized =#False
                        ElseIf LCase(getElem(pars_res,"error",0))="keyfounded"
                          err=3
                          quit = #True
                          Break
                        EndIf
                      Else
                        ;Sprint(msginit$+"Authorized", #colorBrown)  
                        isAuthorized =#True
                        SendQuestion(Connect,get_work_checkwork_string)   
                      EndIf
                      
                    Case #checkjob_id
                      If Not Val(getElem(pars_res,"result",0))
                        ;Sprint(msginit$+">>"+getElem(pars_res,"error",0)+"<<",#colorRed)
                        If LCase(getElem(pars_res,"error",0))="keyfounded"
                          err=3
                          quit = #True
                          Break
                        ElseIf LCase(getElem(pars_res,"error",0))="job_no_longer_exist"
                          err=4
                          quit = #True
                          Break
                        Else
                          Delay(1000)
                          dis=1                          
                        EndIf                        
                      Else                                     
                        quit = #True
                        Break
                      EndIf
                  EndSelect
                EndIf
                If IsJSON(pars_res)
                  FreeJSON(pars_res)
                EndIf 
              Else
                    Sprint(msginit$+"Unknown json",#colorred)
              EndIf
              answer_t$= Right(answer_t$, Len(answer_t$)-pos2)
              pos=FindString(answer_t$, "{")
            Else
              pos=0
            EndIf
          Wend
        EndIf
        
      Case #PB_NetworkEvent_Disconnect
        Debug "getwork disconnected"
        Connect = 0
        err=1
        quit = #True
    EndSelect
    
    
  EndIf
  Delay (1)
  If quit = #False And sendtime And Date()-sendtime>5 And err=0
    ;timeout
    err=5
    quit = #True
  EndIf
Until quit
If Connect
  CloseNetworkConnection(Connect)
EndIf
FreeMemory(*Buffer)
*checkjob\err = err
*checkjob\isRunning=2

 
EndProcedure

Procedure sendSubmitWork(key1$,key2$)
  Protected totalloadbytes, maxloadbytes, loadedbytes, *pp, i, err, batchCRC32, get_work_sendbatch_string.s, quit=#False,  timeout
  Protected Connect, dis=1, pars_res, *Buffer, ReceivedBytes, answer_t$, pos, pos2, answer_f$, tempjson, get_work, Values, get_work_authorize_string.s, id_json_answer,msginit$, isAuthorized
  Shared settings()
  *Buffer = AllocateMemory(65536)
  msginit$ ="[GETWORK_SW] "
  tempjson = CreateJSON(#PB_Any)
  If tempjson   
    get_work = SetJSONObject(JSONValue(tempjson))   
    SetJSONInteger(AddJSONMember(get_work, "id"), #login_id) 
    SetJSONString(AddJSONMember(get_work, "method"), "Login")
    Values =SetJSONArray(AddJSONMember(get_work, "params"))      
    SetJSONString(AddJSONElement(Values), settings("1")\name)     
    SetJSONString(AddJSONElement(Values), settings("1")\pass)
    get_work_authorize_string=ComposeJSON(tempjson)
    FreeJSON(tempjson)
  EndIf
  
  tempjson = CreateJSON(#PB_Any)
    If tempjson   
      get_work = SetJSONObject(JSONValue(tempjson))   
      SetJSONInteger(AddJSONMember(get_work, "id"), #sendkey_id) 
      SetJSONString(AddJSONMember(get_work, "method"), "submitwork")
      Values =SetJSONArray(AddJSONMember(get_work, "params"))         
      SetJSONString(AddJSONElement(Values), settings("1")\hash$)
      SetJSONString(AddJSONElement(Values), key1$)
      SetJSONString(AddJSONElement(Values), key2$)
      get_work_sendbatch_string=ComposeJSON(tempjson)
      FreeJSON(tempjson)
    EndIf
    
  Repeat
    If dis=1
      isAuthorized =#False      
      Connect = OpenNetworkConnection(settings("1")\host ,settings("1")\port,#PB_Network_TCP,10000)
      If Not Connect
        
        While Not Connect And timeout<5
          timeout+1
          Debug "try conect to getwork"
          Delay(1000)
          Connect = OpenNetworkConnection(settings("1")\host ,settings("1")\port,#PB_Network_TCP,10000)
        Wend
        If Not Connect
          ;cant` connect
           Connect = 0
            err=2
            quit = #True
            Break
        EndIf
      EndIf   
      dis=0
      SendQuestion(Connect,get_work_authorize_string) 
      
    EndIf
  
  If Connect
    Select NetworkClientEvent(Connect) 
        Case #PB_NetworkEvent_Data     
        ReceivedBytes = ReceiveNetworkData(Connect, *Buffer, 65536) 
        If ReceivedBytes>0
          answer_t$=PeekS(*Buffer, ReceivedBytes,#PB_Ascii)  
          Debug answer_t$
          pos=FindString(answer_t$, "{")
          While pos                
            pos2=FindString(answer_t$, "}",pos+1)
            If pos2            
              answer_f$=Mid(answer_t$,pos,pos2-pos+1)            
              answer_f$ = RTrim(answer_f$,"}")
              answer_f$ = LTrim(answer_f$,"{")                   
              answer_f$ = "{"+answer_f$+"}"
              Debug">>"+answer_f$        
              pars_res=ParseJSON(#PB_Any, answer_f$)                    
              If pars_res
                id_json_answer=Val(LCase(m_cutHex(getElem(pars_res,"id",0))))
                If id_json_answer
                  Select id_json_answer                            
                    Case #login_id
                       If Not Val(getElem(pars_res,"result",0))
                        If LCase(getElem(pars_res,"error",0))="invalid_login"
                          Sprint(msginit$+">>Invalid Login<<",#colorRed)
                          Delay(1000)
                          dis=1
                          isAuthorized =#False
                        ElseIf LCase(getElem(pars_res,"error",0))="keyfounded"
                          err=3
                          quit = #True
                          Break
                        EndIf
                      Else
                        Sprint(msginit$+"Authorized", #colorBrown)  
                        isAuthorized =#True
                        SendQuestion(Connect,get_work_sendbatch_string)
                        
                        
                      EndIf
                      
                    Case #sendkey_id
                      If Not Val(getElem(pars_res,"result",0))
                        Sprint(msginit$+">>"+getElem(pars_res,"error",0)+"<<",#colorRed)
                        If LCase(getElem(pars_res,"error",0))="keyfounded"
                          err=3
                          quit = #True
                          Break
                        ElseIf LCase(getElem(pars_res,"error",0))="invalid_job"
                          err=4
                          quit = #True
                          Break
                        Else
                          Delay(1000)
                          dis=1
                          isAuthorized =#False
                        EndIf                        
                      Else
                        Sprint(msginit$+"Job was send to host", #colorBrown)                         
                        quit = #True
                        Break
                      EndIf
                  EndSelect
                EndIf
                If IsJSON(pars_res)
                  FreeJSON(pars_res)
                EndIf 
              Else
                    Sprint(msginit$+"Unknown json",#colorred)
              EndIf
              answer_t$= Right(answer_t$, Len(answer_t$)-pos2)
              pos=FindString(answer_t$, "{")
            Else
              pos=0
            EndIf
          Wend
        EndIf
        
      Case #PB_NetworkEvent_Disconnect
        Debug "getwork disconnected"
        Connect = 0
        err=1
        quit = #True
    EndSelect
    
    
  EndIf
  Delay (1)
Until quit
If Connect
  CloseNetworkConnection(Connect)
EndIf
FreeMemory(*Buffer)

ProcedureReturn err  
EndProcedure


Procedure runcuBitCrack(*bitcrackres.CrackStructure)
  Protected  procname$="[SOLVER] ", Output$, err$, Outputcuted$, err, dead$, totaldelemiter,lasttimedead, params$, n, symbolN
  Protected string_win$=LCase("Private key:")
  Protected string_loose$="Reached end of keyspace"
  Protected *Buffer=AllocateMemory(65536)
  Protected cls$=LSet("", 120, Chr(8))
  Shared settings()
  *bitcrackres\isok=1
  
  If settings("1")\device$
    params$+"--device "+settings("1")\device$+" "
  EndIf
  If settings("1")\thread$
    params$+"--threads "+settings("1")\thread$+" "
  EndIf 
  If settings("1")\blocks$
    params$+"--blocks "+settings("1")\blocks$+" "
  EndIf 
  If settings("1")\points$
    params$+"--points "+settings("1")\points$+" "
  EndIf
   
  params$+"--out "+settings("1")\outFilename$+" --keyspace "+settings("1")\rangeB$+":"+settings("1")\rangeE$+" "+settings("1")\address$+" "+settings("1")\powaddress$
  *bitcrackres\Compiler = RunProgram(settings("1")\Progname, params$,"",#PB_Program_Open | #PB_Program_Read)  
  If *bitcrackres\Compiler
    SPrint(procname$+"["+settings("1")\Progname+"] programm running..",#colorYellow)
    SPrint(procname$+"params ["+params$+"]",#colorYellow)
    While ProgramRunning(*bitcrackres\Compiler)
      err$ = ReadProgramError(*bitcrackres\Compiler)
      If err$
          SPrint (procname$+"Error: "+err$,#colorRed)
      EndIf
      If AvailableProgramOutput(*bitcrackres\Compiler) 
        ReadProgramData(*bitcrackres\Compiler, *Buffer, 64)        
        Outputcuted$+PeekS(*Buffer)       
        If CountString(Outputcuted$, #CR$)=2          
          Outputcuted$ = Right(Outputcuted$,Len(Outputcuted$)-1)          
          Output$ = StringField(Outputcuted$, 1, #CR$)
          Outputcuted$=#CR$+StringField(Outputcuted$, 2, #CR$)          
          Print (cls$+Output$)
        EndIf   
      EndIf
      Delay(20)
      If *bitcrackres\killapp
        ;we need kill app
        If ProgramRunning(*bitcrackres\Compiler)
          KillProgram(*bitcrackres\Compiler)
        EndIf
      EndIf
    Wend
    PrintN("")
    If *bitcrackres\killapp=0
      SPrint(procname$+"["+settings("1")\Progname+"] programm finished code["+Str(ProgramExitCode(*bitcrackres\Compiler))+"]",#colorYellow)
      *bitcrackres\isok =  ProgramExitCode(*bitcrackres\Compiler)
    Else
      SPrint(procname$+"["+settings("1")\Progname+"] was killed, due to job is no longer exist",#colorRed)
      *bitcrackres\isok = 0
    EndIf
      *bitcrackres\Compiler=0  
  Else
    SPrint(procname$+"Can't found ["+settings("1")\Progname+"] programm",#colorred) 
  EndIf
  FreeMemory(*Buffer)
  *bitcrackres\isRunning=0
  *bitcrackres\killapp = 0
EndProcedure
  


settings("1")\host="127.0.0.1"
settings("1")\port=8000
settings("1")\name="Friend"
settings("1")\pass="x"
settings("1")\Progname="cuBitCrack.exe"
settings("1")\outFilename$="xxx.txt"
settings("1")\points$="512"
InitNetwork()
OpenConsole()
getprogparam()

If settings("1")\device$  
  If CountString(settings("1")\outFilename$,".")
    settings("1")\outFilename$=StringField(settings("1")\outFilename$,1,".")+settings("1")\device$+"."+StringField(settings("1")\outFilename$,2,".")
  Else
    settings("1")\outFilename$=settings("1")\outFilename$+settings("1")\device$ 
  EndIf
EndIf
sprint("app version: "+#APPVERSION,#colorDarkgrey)
sprint("Host: "+settings("1")\host,#colorDarkgrey)
sprint("Port: "+settings("1")\port,#colorDarkgrey)
sprint("Name: "+settings("1")\name,#colorDarkgrey)
sprint("Pass: "+settings("1")\pass,#colorDarkgrey)
sprint("Prog: "+settings("1")\Progname,#colorDarkgrey)

Define err, msginit$="[MAIN] ", winkey$, quit=#False, bitcrackres.CrackStructure, key1$, key2$, line$, pa$, pk$, checkjob.checkjobStructure, Thread 
While isFind=#False And quit=#False
  Repeat
    err = GetJobHost()
      Select err
        Case 1
          Sprint(msginit$+"Server disconnected",#colorRed)
        Case 2
          Sprint(msginit$+"Server not connected",#colorRed)
        Case 3
          Sprint(msginit$+"Key already founded by host",#colorRed)
          isFind=#True         
        Case 4
          Sprint(msginit$+"All range_scanned",#colorRed)
          isFind=#True
        Case 5
          Sprint(msginit$+"Unknown server error",#colorRed)          
      EndSelect
      If err
        Delay(5000)
      EndIf
  Until err=0 Or err=3 Or err=4
  If Not err
    key1$=""
    key2$=""
    bitcrackres\isRunning = 1
    checkjob\timestamp = Date()    
    Thread = CreateThread(@runcuBitCrack(),@bitcrackres.CrackStructure)
    If Thread
      While bitcrackres\isRunning
        Delay(100)
        If bitcrackres\isRunning And Date()-checkjob\timestamp>#CHECKJOBTIME And checkjob\isRunning = 0
          checkjob\err = 0
          checkjob\isRunning = 1
          checkjob\hash$ = settings("1")\hash$
          CreateThread(@CheckJobHost(), @checkjob.checkjobStructure)
        EndIf
        If checkjob\isRunning = 2
          ;got result about current job
          Select checkjob\err
            Case 1
              ;Server disconnected, maybe enternet issue
            Case 2
              ;Server not connected, maybe enternet issue
            Case 3
              ;Key already founded by host
              ;stop bitcrack and quit
              Sprint(msginit$+"Key already founded by host",#colorRed)
              isFind=#True
              bitcrackres\killapp = 1              
            Case 4
              ;invalid job              
              ;Sprint(msginit$+"Current job is no longer exist",#colorRed)
              bitcrackres\killapp = 1 
            Case 5
              ;timeout, maybe enternet issue
          EndSelect
          checkjob\isRunning=0
          checkjob\timestamp=Date()
          
        EndIf
        If FileSize(settings("1")\outFilename$)>0
          If Not ReadFile(#File, settings("1")\outFilename$ )   
              Sprint( "Something bad happened when read output", #colorRed)
              quit=#True
          Else
              While Not Eof(#File)
                line$ = ReadString(#File,#PB_Ascii)
                pa$ = StringField(line$,1," ")
                pk$ = StringField(line$,2," ")
                If CompareMemoryString(@pa$, @settings("1")\address$, #PB_String_NoCase)=#PB_String_Equal
                  ;mamma mia it is solution!
                  key2$=pk$                
                Else
                  If CompareMemoryString(@pa$, @settings("1")\powaddress$, #PB_String_NoCase)=#PB_String_Equal
                    key1$=pk$
                  Else
                    Sprint( "Invalid collision found", #colorRed)
                    quit=#True
                  EndIf
                EndIf
              Wend
              CloseFile(#File)
              DeleteFile(settings("1")\outFilename$ )
              If key1$="" And key2$<>""
                ;send key immediately! do not wait while pow address will be solved..
                Repeat
                  err = sendSubmitWork(key1$,key2$)
                  Select err
                    Case 1
                      Sprint(msginit$+"Server disconnected",#colorRed)
                    Case 2
                      Sprint(msginit$+"Server not connected",#colorRed)
                    Case 3
                      Sprint(msginit$+"Key already founded by host",#colorRed)
                      isFind=#True
                    Case 4
                      Sprint(msginit$+"invalid job",#colorRed)
                  EndSelect
                Until err=0 Or err=3 Or err=4
              EndIf
          EndIf
          
        EndIf
      Wend
      err =  bitcrackres\isok
      If checkjob\isRunning= 1
        While checkjob\isRunning = 1
          ;wait while jobchecker finished
          Delay(100)
        Wend
        checkjob\isRunning=0
        checkjob\timestamp=Date()
      EndIf
    Else
      Sprint(msginit$+"Can`t create thread to run "+settings("1")\Progname,#colorRed)
      quit=#True
    EndIf    
    If err
      Sprint(msginit$+"Something went wrong during launching "+settings("1")\Progname,#colorRed)
      quit=#True
    EndIf
    If Not err And checkjob\err <>3 And checkjob\err <>4
      If key1$ Or key2$        
        If key2$=""
          Sprint("Didn`t find address in this range -(",#colorDarkgrey)
        EndIf
          Repeat
            err = sendSubmitWork(key1$,key2$)
            Select err
              Case 1
                Sprint(msginit$+"Server disconnected",#colorRed)
              Case 2
                Sprint(msginit$+"Server not connected",#colorRed)
              Case 3
                Sprint(msginit$+"Key already founded by host",#colorRed)
                isFind=#True
              Case 4
                Sprint(msginit$+"invalid job",#colorRed)
             EndSelect
          Until err=0 Or err=3 Or err=4
      Else
        Sprint(msginit$+"Hmm, here problem with solver app!",#colorRed)
        quit=#True
      EndIf 
    EndIf
  EndIf
Wend  
   
Input()
End
; IDE Options = PureBasic 5.31 (Windows - x64)
; ExecutableFormat = Console
; CursorPosition = 800
; FirstLine = 792
; Folding = --
; EnableThread
; EnableXP
; Executable = crackhelperClientX64.exe