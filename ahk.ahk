class ahk
{
	__New(path=""){
		; Here, we let the developer/user specify a(n):
		;	* blank path,
		;	* file name with no extension,
		;	* directory name, or
		;	* absolute path
		; for convenience. In order, the class checks for:
		;	* an absolute or relative path pointing to an existing .DLL file,
		;	* the specified name as a .DLL file (ex. "AHK" would make the class look for "AHK.dll"), or
		;	* a folder. If a folder is specified (or nothing), the class will look for AutoHotkey.dll in the x86a, x86w, or x64w folder below a specified path or the script"s directory.
		
		; If the specified path exists…store its attributes
		szPathAttribs:=FileExist(path)
		
		; If the specified path is a folder
		cIsPathADir:=InStr(szPathAttribs,"D")
		
		; If the path is a DLL file (must not be a folder)
		cIsPathADLLFile:=!cIsPathADir?SubStr(path,StrLen(path)-3,4)=".DLL":false
		
		; Sets working directory…comes up with an automatic working directory if the specified path is a folder, doesn't exist, or isn't a DLL file
		if(!szPathAttribs||cIsPathADir){ ; Path doesn't exist or is a folder
			if(!szPathAttribs) ; Path doesn't exist
				szDirName:=A_ScriptDir ; Set path to CWD of script
			else ; Path exists, but is a folder
				szDirName:=path ; Set the directory name to what the user specified
			; Append "\x", architecture, and "w" if unicode or "a" if ANSI
			szDirName.="\x" (A_PtrSize=4?"86":"64") (A_IsUnicode?"w":"a")
			; Remove "\\x" just in case the directory name had a trailing "\"
			szDirName:=StrReplace(szDirName,"\\x")
		}else ; If the path is absolute, get the folder name of the file
			szDirName:=RegExReplace(path,"(.*)\\.*","$1")
		
		; Sets file name…if the specified path is a folder or blank, file name is set to "AutoHotkey.dll"
		if(path=""||cIsPathADir)
			szLibName:="AutoHotkey.dll"
		else
			szLibName:=RegExReplace(path,".*\\(.*)","$1")
		
		this.path:=szDirName "\" szLibName
		
		if(!FileExist(this.path))
			return,this.error("Unable to find " this.path " - the file does not exist.")
		else if(SubStr(this.path,StrLen(this.path)-3,4)!=".DLL")
			return,this.error("The specified path must be a .DLL file or a folder containing a valid AutoHotkey.dll file variation: " this.path " is not valid.")
		
		FileCopy,% this.path,% this.path:=A_Temp "\" A_MM "-" A_DD "-" A_YYYY "_" A_Hour "-" A_Min "-" A_Sec "-" A_MSec ".dll"
		if(!hReturnValue:=DllCall("LoadLibrary",Str,this.path))
			return,this.error("Unable to load library: " this.path "`r`nYou should first uninstall/reinstall this program. If that does not resolve the issue, please contact the developer.")
	}
	
	error(szMessage){
		MsgBox,16,Error,% "AutoHotkey.dll - Error`r`n`r`n" szMessage
		return,false
	}
	
	do(code=""){
		if(!code)
			code:=this.code
		
		if(!this.stickyCode)
			this.stickyCode:="ExitApp"
		
		if(InStr(code,"$")){
			Loop,Parse,code,$
			{	Loop,Parse,A_LoopField
				{	if(!RegExMatch(A_LoopField,"[a-zA-Z0-9_]"))
						break
					thisVar.=A_LoopField
				}
				contents:=this[thisVar]
				if(contents)
					StringReplace,code,code,$%thisVar%,%contents%
				thisVar:=""
			}
		}
		return,DllCall(this.path "\ahktextdll",Str,"#NoTrayIcon`nSetBatchLines,-1`n" code "`n" this.stickyCode)
	}
}