#pragma rtGlobals=1		// Use modern global access method.
#pragma hide=1

menu "4XcLTP"


"4XcLTP", Panel() 

end 

////////// Bryce's additions
//Function OnlineResistances(s) 
//STRUCT WMBackgroundStruct &s

//return 0
//End

//Function StartOnlineResistances()
//CtrlNamedBackground resist, start=120, period=3600, proc=OnlineResistances
//End

//Function StopOnlineResistances()
//CtrlNamedBackground resist, stop
//End

///////////////////////////////////////////////////////////////////
////////////////////////////////////This script has been created by Claudio Elgueta, using IGOR PRO 6.2.2.2
////////////////////////////////////and NIDAQ tools MX 1.01. Comments, suggestions, requests, please write me at claudioez@gmail.com 
//////////////////////////////////// or claudio.elgueta@physiologie.uni-freiburg.de				

//2.76 Fixed problem with paired pulses that now can be eliminated by setting PP interval to 0
// Added warning message to reset

Function Panel()  

NewPath /C/O/Q/Z path1, "c:" 

Newdatafolder /O Root:cLTP
Newdatafolder /O  Root:cLTP:Protocols
String /G protocolsList
Setdatafolder Root:cLTP

newdatafolder /O Root:cLTP:Raw_Sweeps
newdatafolder /O Root:cLTP:Averaged_Sweeps
VARIABLE/g TotalProtduration,RangeGvar,Timewindow,i,j,k,recordTime,ppC,RecordCheck, C1i,C2i, C3i,C4i,C1DIO,C2DIO,C3DIO,C4DIO
C1DIO=1; C2DIO=2;C3DIO=3;C4DIO=4
VARIABLE/g Npeak,SweepLength,C1,C2,C3,C4, DistpPProtocol,Fmuestreo,dur,n,gain,verRmin,verRmax,v_max,DistpP,durpulso,LbaseI,Lbasef
VARIABLE/g Numpulsos,frecpulsos,numrafagas,frecrafagas,numtrenes,frectrenes,Pdelay1,Pdelay2,Pdelay3,Pdelay4,DelayedStim,PDdelay1,PDdelay2,PDdelay3,PDdelay4     



string /G CCoord="C1T=.5;C1B=5;C2T=6;C2B=10.5;C3T=10.5;C3B=15;C4T=15;C4B=19.5"
string /G ColorList="C1=34816,34816,34816;C2=16384,28160,65280;C3=0,52224,26368;C4=52224,17408,0"
String /G MarkerList="C1=8;C2=6C3=7;C4=2"
i=0;j=0;k=0;RangeGvar=5;Npeak=1
string /g currentDev= stringfromlist(0,fdaqmx_devicenames(),";")
String/G  namefile=replacestring("/",secs2date(Datetime,0),"-") //// Si la fecha del computador esta separada por / Igor encontrara un error al grabar, para esto cambie el modeo de la fecha en panel de control o cambie el nombre del archivo
string/g NombreProtocolo

String quote = "\""
string  /G DIOports=quote
variable F
For (F=0; F<fdaqmx_numdioports(currentDev); F=F+1)
DioPorts=DioPorts+num2str(F)+";"
endfor
DioPorts=DioPorts+quote

String/g  DevList=quote+fdaqmx_devicenames()+quote

variable /G CurrDIOport=nan
For (F=0; F<fdaqmx_numdioports(currentDev); F=F+1)
	if (fdaqmx_DIO_PortWidth(currentDev,F)>3)
	CurrDIOport=F
	break
	endif
endfor
if (CurrDIOport==nan)
Doalert /T="Not enough digital outputs in this card" 0, "Stimulation will be shared between channels each channel"
C1DIO=1; C1DIO=1;C3DIO=1;C4DIO=1
endif

///////////////////////////////////////////////////////////////////////////Notice this is the section of initialization of most variables. A simple way of changing default values is just to modify them here.

C1i=1;C2i=2;C3i=3;C4i=4 ;Pdelay1=5;Pdelay2=5;Pdelay3=5;Pdelay4=5;ppC=0;TotalProtduration=0
dur=60; n=4 ;gain=10000 ; DistPp=0;fmuestreo=10000; Durpulso=0.2;Pddelay1=10;PDdelay2=10;PDdelay3=10;PDdelay4=10
Numpulsos=4; frecpulsos=100;numrafagas=10;frecrafagas=5;numtrenes=4;frectrenes=0.05;SweepLength=60000

Dowindow /K LTP

newpanel /k=2/N=LTP /W=(189,189,610,624)

	Button Stop,pos={10,345},size={100,25},proc=stop,title="Stop",fSize=14
	Button Ad,pos={10,310},size={100,25},proc=Acquire,title="Acquire",fSize=14
	Button Reset,pos={125,345},size={100,25},proc=reset,title="Reset",fSize=14
	Button Test1,pos={280,305},size={50,20},proc=Test,title="Test 1",fcolor=(34816,34816,34816)
	Button Test2,pos={340,305},size={50,20},proc=Test,title="Test 2",fcolor=(16384,28160,65280)
	Button Test3,pos={280,330},size={50,20},proc=Test,title="Test 3",fcolor=(0,52224,26368)
	Button Test4,pos={340,330},size={50,20},proc=Test,title="Test 4",fcolor=(52224,17408,0)
	
	Button RunProtocolG,pos={10,385},size={100,20},proc=RunProtocol,title="Run all protocols"
	Button RunProtocol1,pos={210,385},size={50,20},proc=RunProtocoli,title="Run p1",fcolor=(34816,34816,34816)
	Button Test2,pos={340,305},size={50,20},proc=Test,title="Test 2",fcolor=(16384,28160,65280)
	Button RunProtocol2,pos={360,385},size={50,20},proc=RunProtocoli,title="Run p2",fcolor=(16384,28160,65280)
	Button RunProtocol3,pos={210,410},size={50,20},proc=RunProtocoli,title="Run p3",fcolor=(0,52224,26368)
	Button RunProtocol4,pos={360,410},size={50,20},proc=RunProtocoli,title="Run p4",fcolor=(52224,17408,0)
	CheckBox estimular,pos={280,280},size={78,18},title="Stimulate",value=1
	CheckBox grabar,pos={145,320},size={61,18},title="Record", value= 0,variable=RecordCheck
	PopupMenu p1,pos={120,385},size={70,21},mode=1,value= "No protocol"
	PopupMenu p2,pos={270,385},size={70,21},mode=1,value= "No protocol"
	PopupMenu p3,pos={120,410},size={70,21},mode=1,value= "No protocol"
	PopupMenu p4,pos={270,410},size={70,21},mode=1,value= "No protocol"
	//ValDisplay tiempo,pos={10,280},size={150,20},title="Time(mins)",limits={0,0,0},barmisc={0,1000},value= #"root:cLTP:Valtmpo"
	ValDisplay nT ,pos={10,280},size={150,20},title="# of Sweeps:",limits={0,0,0},barmisc={0,1000},value= #"root:cLTP:numTraces"	
	PopupMenu AOselect,pos={10,410},size={70,21},mode=1,title="AO",value= "No protocol"

	Button AmpDisp,pos={120,49},size={90,25},disable=1,proc=AmpDisplay,title="Amplitude"
	Button  AreaDisp,pos={20,91},size={90,25},disable=1,proc= AreaDisplay,title="Area"
	Button SlopeDisplay,pos={20,49},size={90,25},disable=1,proc=SlopeDisplay,title="Slope"
	Button HFDisplay,pos={120,91},size={90,25},disable=1,proc=HFDisplay,title="Half Width"
	Button Osc,pos={20,130},size={150,30},disable=1,proc=Oscdisp,title="Oscilloscope mode"
	Checkbox Npeak ,pos={20,180},size={150,25},variable=Npeak, value=1, title="analyze negative peak"
	
	Button C1disp,pos={240,49},size={50,20},disable=1,proc=CDisplay,title="C1 trace",fcolor=(34816,34816,34816)
	Button C1Adisp,pos={300,49},size={50,20},disable=1,proc=CDisplay,title="C1 avg",fcolor=(34816,34816,34816)
	Button C2disp,pos={240,80},size={50,20},disable=1,proc=CDisplay,title="C2 trace",fcolor=(16384,28160,65280)
	Button C2Adisp,pos={300,80},size={50,20},disable=1,proc=CDisplay,title="C2 avg",fcolor=(16384,28160,65280)
	Button C3disp,pos={240,110},size={50,20},disable=1,proc=CDisplay,title="C3 trace",fcolor=(0,52224,26368)
	Button C3Adisp,pos={300,110},size={50,20},disable=1,proc=CDisplay,title="C3 avg",fcolor=(0,52224,26368)	
	Button C4disp,pos={240,140},size={50,20},disable=1,proc=CDisplay,title="C4 trace",fcolor=(52224,17408,0)
	Button C4Adisp,pos={300,140},size={50,20},disable=1,proc=CDisplay,title="C4 avg",fcolor=(52224,17408,0)

	Button carpeta,pos={20,240},size={80,20},proc=carpeta,title=" Folder"
	popupmenu DIOselect,pos={20,165},size={172,21},title="DIO port",value=#DioPorts,popvalue=num2str(CurrDIOport)
	popupmenu devicename,pos={20,75},size={172,21},title="Device",value=# DevList
	popupmenu RangeC,pos={20,105},size={172,21},title="Acq range (+/- Volts)",value= "10;5;1;0.2", popvalue=(num2str(RangeGvar))
	popupmenu ModeC,pos={20,135},size={172,21},title="Reference mode",value= "RSE;NRSE;Diff;PDIFF",popvalue="RSE"
	SetVariable C1i,pos={240,95},size={50,20},title="C1",variable= C1i, limits={0,fdaqmx_numanaloginputs(currentDev),0} ,fcolor=(34816,34816,34816)//THESE variables need to be entered to the channelslist
	SetVariable C2i,pos={300,95},size={50,20},title="C2",variable= C2i, limits={0,fdaqmx_numanaloginputs(currentDev),0},fcolor=(16384,28160,65280)
	SetVariable C3i,pos={240,120},size={50,20},title="C3",variable= C3i, limits={0,fdaqmx_numanaloginputs(currentDev),0},fcolor=(0,52224,26368)
	SetVariable C4i,pos={300,120},size={50,20},title="C4",variable= C4i, limits={0,fdaqmx_numanaloginputs(currentDev),0}	,fcolor=(52224,17408,0)
	SetVariable C1DIO,pos={240,170},size={50,20},title="C1",variable= C1DIO, limits={0,fdaqmx_DIO_PortWidth(currentDev,CurrDIOport),0} ,fcolor=(34816,34816,34816)//THESE variables need to be entered to the channelslist
	SetVariable C2DIO,pos={300,170},size={50,20},title="C2",variable= C2DIO, limits={0,fdaqmx_DIO_PortWidth(currentDev,CurrDIOport),0},fcolor=(16384,28160,65280)
	SetVariable C3DIO,pos={240,195},size={50,20},title="C3",variable= C3DIO, limits={0,fdaqmx_DIO_PortWidth(currentDev,CurrDIOport),0},fcolor=(0,52224,26368)
	SetVariable C4DIO,pos={300,195},size={50,20},title="C4",variable= C4DIO, limits={0,fdaqmx_DIO_PortWidth(currentDev,CurrDIOport),0},fcolor=(52224,17408,0)
	SetVariable filename,pos={138,240},size={200,21},title="Filename",value= namefile
	SetVariable recordT,pos={20,220},size={200,21},title="Save to disk every n traces",value= recordTime
	SetVariable gain,pos={220,45},size={130,21},title="Gain",value= gain,  proc=Gvariablechanged
	SetVariable Fmuestreo,pos={20,45},size={172,21},title="Sampling Rate",value= Fmuestreo, proc=Gvariablechanged

	SetVariable Nsweeps,pos={20,115},size={168,21},disable=1,title="Average N sweeps    ",value= n,bodyWidth= 50, limits={1,inf,1}
	SetVariable SweepLength, pos={220,90}, value=SweepLength,size={150,30}, title="Sweep Lenght (ms)"
	SetVariable interstimulus,pos={28,90},size={160,20},disable=1,title="Stimulus Interval(s)",value=dur,bodyWidth= 50
	SetVariable DurPulso,pos={180,115},size={180,21},disable=1,title="Pulse length (ms)",value= durpulso,bodyWidth= 40,proc=Pulseinit,limits={0,SweepLength,0.1}
	SetVariable DistPp,pos={25,140},size={170,21},disable=1,title="PP interval (ms)", value= DistpP, proc=Pulseinit,limits={0,SweepLength-durpulso,1}

	
	SetVariable Pdelay1 pos={170,200},bodywidth=50,size={120,21},title="C1", Value=PDdelay1, proc=Pulseinit, limits={durpulso,SweepLength,1},fcolor=(34816,34816,34816)
	SetVariable Pdelay2 pos={250,200},bodywidth=50,size={120,21},title="C2", Value=PDdelay2, proc=Pulseinit, limits={durpulso, SweepLength,1},fcolor=(16384,28160,65280)
	SetVariable Pdelay3 pos={250,225},bodywidth=50,size={120,21},title="C3", Value=PDdelay3, proc=Pulseinit, limits={durpulso,SweepLength,1},fcolor=(0,52224,26368)
	SetVariable Pdelay4 pos={170,225},bodywidth=50,size={120,21},title="C4", Value=PDdelay4, proc=Pulseinit, limits={durpulso,SweepLength,1},fcolor=(52224,17408,0)

	CheckBox DelayedStim, pos={40,175},size={140,20},title="Delayed sweeps (ms)", value=0,variable=DelayedStim, fstyle=1	
	SetVariable DelayC1 pos={0,200},bodywidth=40,size={100,21},title="C1", Value=Pdelay1,fcolor=(34816,34816,34816)
	SetVariable DelayC2 pos={70,200},bodywidth=40,size={100,21},title="C2", Value=Pdelay2,fcolor=(16384,28160,65280)
	SetVariable DelayC3 pos={0,225},bodywidth=40,size={100,21},title="C3", Value=Pdelay3,fcolor=(0,52224,26368)
	SetVariable DelayC4 pos={70,225},bodywidth=40,size={100,21},title="C4", Value=Pdelay4,fcolor=(52224,17408,0)
	

	CheckBox C1,pos={20,40},size={80,20},title="Channel 1",variable= C1,value=0,proc=waveinit,fcolor=(34816,34816,34816)
	CheckBox C2,pos={120,40},size={80,20},title="Channel 2",variable= C2,value=0,proc=waveinit, Value=Pdelay2,fcolor=(16384,28160,65280)
	CheckBox C3,pos={20,60},size={80,20},title="Channel 3",variable= C3,value=0,proc=waveinit, Value=Pdelay3,fcolor=(0,52224,26368)
	CheckBox C4,pos={120,60},size={80,20},title="Channel 4",variable= C4,value=0,proc=waveinit, Value=Pdelay4,fcolor=(52224,17408,0)
	
	
	Button reviewPrt,pos={20,200},size={80,20},disable=1,proc=reviewPrt,title="Preview"
	Button SavePrt,pos={160,230},size={60,20},disable=1,proc=SavePrt,title="Save"
	Button LoadPrt,pos={290,230},size={100,20},disable=1,proc=LoadPrt,title="Load protocols"
	Button DeletePrt,pos={220,230},size={60,20},disable=1,proc=DeletePrt,title="Delete"
	Button AddFileDIO,pos={20,170},size={140,20},disable=1,proc=AddDIOCW,title="Add DIO custom wave"
	Button AddFileAO,pos={180,170},size={140,20},disable=1,proc=AddAOCW,title="Add AO custom wave"
	SetVariable NombreProtocol pos={120,200},size={200,20},disable=1,value=NombreProtocolo,title="Protocol name", limits={-inf,inf,0}
	SetVariable NumPulsos,pos={20,40},size={160,21},disable=1,title="Pulse Repetitions",limits={1,1000,1},value= Numpulsos,live= 1
	SetVariable FrecPulsos,pos={192,40},size={120,21},disable=1,title="Frequency",limits={1,10000,1},value= frecpulsos,live= 1
	SetVariable NumRafagas,pos={20,70},size={160,21},disable=1,title="Burst Repetitions",limits={1,1000,1},value= numrafagas,live= 1
	SetVariable FrecRafagas,pos={192,70},size={120,21},disable=1,title="Frequency", value= frecrafagas,live= 1
	SetVariable NumTrenes,pos={20,100},size={160,21},disable=1,title="Train Repetitions",limits={1,1000,1},value= numtrenes,live= 1
	SetVariable FrecTrenes,pos={192,100},size={120,21},disable=1,title="Frequency",value= frectrenes,live= 1
	SetVariable DistPpProtocol,pos={157,140},size={190,21},disable=1,title="PP interval",value= DistpPProtocol
	CheckBox PpareadoProtocol,pos={20,145},size={95,18},disable=1,title="Paired pulse",value= 0
	PopupMenu Protocolos,pos={21,230},size={70,21},disable=1,mode=1,value= "No protocol"
	SetVariable TotalProtduration,pos={20,125},size={172,21},title="Total duration(s)",value= TotalProtduration ///note we need to update this functions and wave init, proc=Pulseinit

	TabControl tabs,pos={10,10},size={392,262},proc=hidetab
	TabControl tabs tabLabel(0)="Experiment", tabLabel(1)="Display",tabLabel(2)="Protocol",tabLabel(3)="General settings"

	
string allcontrols=Controlnamelist("LTP",";")
modifycontrollist /z allcontrols fsize=13, font="Calibri"
	
	groupbox Ainputs title="Analog inputs", pos={240,75}, size={0,0}, frame=0,font="Calibri",fSize=14,fstyle=1, labelBack=0
	groupbox DigOutputs title="Digital outputs", pos={240,150}, size={0,0}, frame=0,font="Calibri",fSize=14,fstyle=1, labelBack=0
	groupbox Pdelay title="Pdelay (ms)", pos={250,175}, size={0,0}, frame=0,font="Calibri",fSize=14,fstyle=1, labelBack=0
	Button Stop,pos={10,345},size={100,25},proc=stop,title="Stop",fSize=14
	Button Ad,pos={10,310},size={100,25},proc=Acquire,title="Acquire",fSize=14
	Button Reset,pos={125,345},size={100,25},proc=reset,title="Reset",fSize=14
	CheckBox grabar,pos={140,315},size={61,18},title="Record", value= 0,variable=RecordCheck,fSize=15,fColor=(65280,0,0),fstyle=1
	//ValDisplay tiempo fstyle=1,fColor=(4352,4352,4352),fsize=15,frame=0,valueBackColor=(60928,60928,60928)
	ValDisplay nT fstyle=1,fColor=(4352,4352,4352),fsize=15,frame=0,valueBackColor=(60928,60928,60928)

hidetab("config",0)
Setdatafolder root:
Pulseinit ("DurPulso",.2,"varStr","Durpulso") 

end
///////////////////////////////////////////////////////////////////////
function hidetab(name,tab)
string name
variable tab

Button carpeta, disable=(tab!=3)
Setvariable filename,disable=(tab!=3)
Setvariable SweepLength, disable=(tab!=0)
SetVariable Interstimulus disable=(tab!=0)
SetVariable Nsweeps disable=(tab!=0)
SetVariable DurPulso disable=(tab!=0)
SetVariable Pdelay1 disable=(tab!=0)
SetVariable Pdelay2 disable=(tab!=0)
SetVariable Pdelay3 disable=(tab!=0)
SetVariable Pdelay4 disable=(tab!=0)
SetVariable DelayC1 disable=(tab!=0)
SetVariable DelayC2 disable=(tab!=0)
SetVariable DelayC3 disable=(tab!=0)
SetVariable DelayC4 disable=(tab!=0)
groupbox Pdelay disable=(tab!=0)

Setvariable DistPp disable=(tab!=0)
Checkbox C1, disable=(tab!=0)
Checkbox C2, disable=(tab!=0)
Checkbox C3, disable=(tab!=0)
Checkbox C4, disable=(tab!=0)
Checkbox DelayedStim, disable=(tab!=0)

Button AreaDisp disable=(tab!=1)
Button AmpDisp disable=(tab!=1)
Button SlopeDisplay disable=(tab!=1)
Button HFdisplay disable=(tab!=1)
Button Osc disable=(tab!=1)
Checkbox Npeak disable=(tab!=1)
Button C1disp disable=(tab!=1)
Button C1Adisp disable=(tab!=1)
Button C2disp disable=(tab!=1)
Button C2Adisp disable=(tab!=1)
Button C3disp disable=(tab!=1)
Button C3Adisp disable=(tab!=1)
Button C4disp disable=(tab!=1)
Button C4Adisp disable=(tab!=1)

Button reviewPrt disable=(tab!=2)
Button SavePrt disable=(tab!=2)
Button LoadPrt disable=(tab!=2)
Button AddFileDIO disable=(tab!=2)
Button AddFileAO disable=(tab!=2)
Button DeletePrt disable=(tab!=2)
SetVariable NumPulsos disable=(tab!=2)
SetVariable FrecPulsos disable=(tab!=2)
SetVariable NumRafagas disable=(tab!=2)
SetVariable FrecRafagas disable=(tab!=2)
SetVariable NumTrenes disable=(tab!=2)
SetVariable FrecTrenes disable=(tab!=2)
SetVariable NombreProtocol  disable=(tab!=2)
PopupMenu Protocolos disable=(tab!=2)
Checkbox PpareadoProtocol disable=(tab!=2)
Setvariable DistPpProtocol disable=(tab!=2)
Setvariable TotalProtduration disable=(tab!=2)

popupmenu modeC disable=(tab!=3)
popupmenu RangeC disable=(tab!=3)
Setvariable gain, disable=(tab!=3)
Setvariable Fmuestreo, disable=(tab!=3)
popupmenu devicename, disable=(tab!=3)
popupmenu DIOselect, disable=(tab!=3)
Setvariable C4i, disable=(tab!=3)
Setvariable C3i, disable=(tab!=3)
Setvariable C2i, disable=(tab!=3)
Setvariable C1i, disable=(tab!=3)
SetVariable C1DIO, disable=(tab!=3)
SetVariable C2DIO, disable=(tab!=3)
SetVariable C3DIO, disable=(tab!=3)
SetVariable C4DIO, disable=(tab!=3)
SetVariable recordT, disable=(tab!=3)
groupbox Ainputs, disable=(tab!=3)
groupbox DigOutputs, disable=(tab!=3)
end
///////////////////////////////////////////////
function acquire (name):BUTTONCONTROL 
string name		
//StartOnlineResistances()
	setdatafolder root:cLTP:
	Variable /G valtmpo,valtmpoi
	
	if (valtmpoi==0)
	variable hr,mins,seg
	String Tmpo=time()
	sscanf tmpo,"%d%*[:]%d%*[:]%d",hr,mins,seg
	valtmpoi=((hr*60+mins)*60)+(seg)
	valtmpo=0
	endif

	Variable /G numTraces //BG edit 18Dec19


string /G currentDev,DioList
	string /g thewavelist=""
	VARIABLE/G  CurrDIOport,dur,C1, C2,C3,C4,delayedstim,Pdelay1,Pdelay2,Pdelay3,Pdelay4,sweeplength,C1DIO,C2DIO,C3DIO,C4DIO
	
	if (C1+C2+C3+C4<=0)
	Doalert 0, "Please select at least one acquistion channel"
	abort
	endif
	
	if (delayedstim==1)
	if (Pdelay1*c1>=dur || Pdelay2*c2>=dur  || Pdelay3*c3>=dur || Pdelay4*c4>=dur)
	Doalert 0, "Interstimulus interval cannot be smaller than channel delay"
	abort
	endif
	endif
	
	 Dowindow/F ltp
	Button Ad,win=ltp, disable=1
	Button RunProtocolG,disable=1
		Button RunProtocol1,disable=1
		Button RunProtocol2,disable=1
		Button RunProtocol3,disable=1
		Button RunProtocol4,disable=1
		Button test1,disable=1
		Button test2,disable=1
		Button test3,disable=1
		Button test4,disable=1
		 checkbox C1,disable=1
		checkbox C2,disable=1
		checkbox C3,disable=1
		checkbox C4,disable=1
	
	Variable numTicks = dur * 60 
	DioList=""
	Controlinfo /W=LTP ModeC
	string modeCv=s_value
	Controlinfo  /W=LTP  RangeC
	string RangeCv=s_value
	
		if (delayedstim==0)
		variable i
		string wavesL=wavelist("C*wave",";","")
		For (i=0;i<(itemsinlist(wavesL));i=i+1)		
		thewavelist=thewavelist+stringfromlist(i ,wavesL,";")+ ", "
		string  TT=stringfromlist(i ,wavesL,";")
		TT=TT[1]
		variable /G $("C"+TT+"i")
		Nvar CiT= $("C"+TT+"i")
		variable /G $("C"+TT+"DIO")
		Nvar CDioT= $("C"+TT+"DIO")
		DioList=DioList+"/"+currentDev+"/port"+num2str(CurrDIOport)+"/line"+num2str(CDioT)+","
		thewavelist=thewavelist+num2str(CiT)+"/"+modeCv+","+"-"+RangeCv+","+RangeCv+";"
		endfor
		DioList=removeending(DioList)
		TheWaveList=removeending(TheWaveList)
		CtrlNamedBackground RunLoopG, period=numTicks, proc=RunLoopG
		CtrlNamedBackground RunLoopG, start		
		endif
i=0
if (delayedstim==1)					//	This is to define which wave to start first 
DIOlist=""
	make /o/n=4 DelayW
	Delayw[0]=Pdelay1 
	Delayw[1]=Pdelay2
	Delayw[2]=Pdelay3
	Delayw[3]=Pdelay4
	if (c1==0)
	Delayw[0]=Nan
	endif
	if (c2==0)
	Delayw[1]=Nan
	endif
	if (c3==0)
	Delayw[2]=Nan
	endif
	if (c4==0)
	Delayw[3]=Nan
	endif
	
	
	
	VARIABLE /g V_MINT
	variable V_minb, v_min
	v_mint=inf
	Do
	
	 if (v_mint!=inf && abs(v_mint-v_min)>=sweeplength/500 )	
		V_MINT=inf
		thewavelist=""
		DioList=""
		endif
		
		Do
		wavestats  /q Delayw
		V_minb= v_min	
	
		if (v_mint==inf || abs(v_mint-v_min)<sweeplength/333 )
		V_MINT=v_min

			if (exists(("C"+num2str(V_minloc+1)+"wave"))==0)
			DelayW[v_minloc]=nan
			else
			variable /G $("C"+num2str(V_minloc+1)+"i")
			Nvar CiT2= $("C"+num2str(V_minloc+1)+"i")
			variable /G $("C"+num2str(V_minloc+1)+"DIO")
			Nvar CDioT2= $("C"+num2str(V_minloc+1)+"DIO")
			DioList+="/"+currentDev+"/port"+num2str(CurrDIOport)+"/line"+num2str(CDioT2)+","
			thewavelist+="C"+num2str(V_minloc+1)+"wave, "+num2str(CiT2)+"/"+modeCv+","+"-"+RangeCv+","+RangeCv+";"
			DelayW[v_minloc]=nan
			endif
		else 
			  break		
			endif
	while (V_numNaNs<4)
	

	string /G $("Wlist"+num2str(i))
	Svar Twlist=$("Wlist"+num2str(i))

	string /G $("Diolist"+num2str(i))
	Svar TDiolist=$("Diolist"+num2str(i))

		TDiolist=removeending(DioList)
		Twlist=removeending(TheWaveList)
	CtrlNamedBackground $("RunLoop"+num2str(i)), period=numTicks, proc=RunLoopS
	CtrlNamedBackground $("RunLoop"+num2str(i)), start=(ticks+v_mint*60)
	
		i=i+1
	while (V_numNaNs<4)
endif
	setdatafolder root:
END
//////////////////////////////////////////////////////////////////////////////////
Function RunLoopS(s)
STRUCT WMBackgroundStruct &s
setdatafolder root:cLTP:
string input=s.name 
 	VARIABLE /g V_MINT
String /G TwlistG,DioList, currentDev,thewavelist
string DioClock="/"+currentDev+"/ai/sampleclock"
	input=input[strlen(input)-1]
	
	string /G $("Wlist"+(input))
	Svar Twlist=$("Wlist"+(input))
	 TwlistG=twlist
	string /G $("Diolist"+(input))
	Svar TDiolist=$("Diolist"+(input))
string Npulse1,Npulse2,Npulse3,Npulse4 
Npulse1=stringfromlist(0,DioList,",")
Npulse1=Npulse1[strlen(Npulse1)-1]
Npulse1="Pulse"+Npulse1
Npulse2=stringfromlist(1,DioList,",")
Npulse2=Npulse2[strlen(Npulse2)-1]
Npulse2="Pulse"+Npulse2
Npulse3=stringfromlist(2,DioList,",")
Npulse3=Npulse3[strlen(Npulse3)-1]
Npulse3="Pulse"+Npulse3
Npulse4=stringfromlist(3,DioList,",")
Npulse4=Npulse4[strlen(Npulse4)-1]
Npulse4="Pulse"+Npulse4
if (itemsinlist(thewavelist,";")==1)
DAQmx_DIO_Config    /CLK={DioClock,1} /Dev=currentDev /DIR=1 /LGRP = 1  /Wave={$(Npulse1)} TDiolist
endif
if (itemsinlist(thewavelist,";")==2)
DAQmx_DIO_Config    /CLK={DioClock,1} /Dev=currentDev /DIR=1 /LGRP = 1  /Wave={$(Npulse1),$(Npulse2)} TDiolist
endif
if (itemsinlist(thewavelist,";")==3)
DAQmx_DIO_Config    /CLK={DioClock,1} /Dev=currentDev /DIR=1 /LGRP = 1 /Wave={$(Npulse1),$(Npulse2),$(Npulse3)}  TDiolist
endif
if (itemsinlist(thewavelist,";")==4)
DAQmx_DIO_Config    /CLK={DioClock,1} /Dev=currentDev /DIR=1 /LGRP = 1   /Wave={$(Npulse1),$(Npulse2),$(Npulse3),$(Npulse4)} TDiolist
endif

DAQmx_Scan /Dev=currentDev /EOSH="stop(num2str(0));record()" /BKG WAVES=(Twlist)
setdatafolder root:
return 0
end
///////////////////////////////////////////////////////////////////////////////////////////////////
Function RunLoopG(s)
STRUCT WMBackgroundStruct &s
setdatafolder root:cLTP:
WaveStats/Z/Q/R=(0.015,0.115) C1wave
WAVE current = C1wave

//begin BG edit
Variable/G numTraces
if (V_avg !=0)
	printf "Series resistance      %*.*f\r", 2,3,(25/(current[150]-V_min))
	printf "Input resistance        %*.*f\r", 4,2,(25/(current[150]-mean(current,0.05,0.10)))
endif
SetDataFolder root:cLTP:Raw_Sweeps
String/G cellFolder = GetIndexedObjNameDFR(GetDataFolderDFR( ), 4, 0)
SetDataFolder root:cLTP:Raw_Sweeps:$(GetIndexedObjNameDFR(GetDataFolderDFR( ), 4, 0)):C1
numTraces = CountObjectsDFR(GetDataFolderDFR( ),1)
setdatafolder root:cLTP: 
// end BG edit

String /G TheWaveList,DioList, currentDev
string DioClock="/"+currentDev+"/ai/SampleClock"

string Npulse1,Npulse2,Npulse3,Npulse4 
Npulse1=stringfromlist(0,DioList,",")
Npulse1=Npulse1[strlen(Npulse1)-1]
Npulse1="Pulse"+Npulse1
Npulse2=stringfromlist(1,DioList,",")
Npulse2=Npulse2[strlen(Npulse2)-1]
Npulse2="Pulse"+Npulse2
Npulse3=stringfromlist(2,DioList,",")
Npulse3=Npulse3[strlen(Npulse3)-1]
Npulse3="Pulse"+Npulse3
Npulse4=stringfromlist(3,DioList,",")
Npulse4=Npulse4[strlen(Npulse4)-1]
Npulse4="Pulse"+Npulse4


if (itemsinlist(thewavelist,";")==1)
DAQmx_DIO_Config   /CLK={DioClock,1} /Dev=currentDev /DIR=1 /LGRP = 1  /Wave={$(Npulse1)} DioList
endif
if (itemsinlist(thewavelist,";")==2)
DAQmx_DIO_Config   /CLK={DioClock,1} /Dev=currentDev /DIR=1 /LGRP = 1  /Wave={$(Npulse1),$(Npulse2)} DioList
endif
if (itemsinlist(thewavelist,";")==3)
DAQmx_DIO_Config   /CLK={DioClock,1} /Dev=currentDev /DIR=1 /LGRP = 1  /Wave={$(Npulse1),$(Npulse2),$(Npulse3)} DioList
endif
if (itemsinlist(thewavelist,";")==4)
DAQmx_DIO_Config   /CLK={DioClock,1} /Dev=currentDev /DIR=1 /LGRP = 1  /Wave={$(Npulse1),$(Npulse2),$(Npulse3),$(Npulse4)} DioList
endif
 DAQmx_Scan /DEV=currentDev /EOSH="stop(num2str(0));record()" /BKG WAVES=(TheWaveList)
variable /g Tasknumber=V_DAQmx_DIO_TaskNumber
return 0
end
/////////////////////////////////////////////////////////////

function stop(detener) : ButtonControl
string detener
Variable /G Tasknumber,protocolStatus
string /g currentdev
fDAQmx_DIO_Finished(currentdev, Tasknumber)
 fDAQmx_WaveformStop(currentdev)
 fDAQmx_ScanStop(currentdev)
 fDAQmx_ResetDevice(currentdev)
 protocolStatus=0
//Killwaves /Z Pulso
if (cmpstr(detener,"stop")==0)
 CtrlNamedBackground _all_, stop
 Button Ad,win=ltp, disable=0
 endif
 	
	Button RunProtocolG, win=LTP, disable=0
	Button RunProtocol1,win=LTP,disable=0
	Button RunProtocol2,win=LTP,disable=0
	Button RunProtocol3,win=LTP,disable=0
	Button RunProtocol4,win=LTP,disable=0
	Button test1,win=LTP,disable=0
	Button test2,win=LTP,disable=0
	Button test3,win=LTP,disable=0
	Button test4,win=LTP,disable=0

 setdatafolder root:
end
/////////////////////////////////////////////////
function RunProtocol(RunProtocol): Buttoncontrol
string RunProtocol
setdatafolder root:cLTP

string /g CCoord,colorlist,currentdev
 fDAQmx_ScanStop(currentdev)
 fDAQmx_ResetDevice(currentdev)
 CtrlNamedBackground _all_, stop
 	Controlinfo /W=LTP ModeC
	string modeCv=s_value
	Controlinfo  /W=LTP  RangeC
	string RangeCv=s_value
		
 		variable /G CurrDIOport,Valtmpo,fmuestreo
 		string PDFname="Protocol_at_"+num2str(Valtmpo)
 		newdatafolder /o root:CLTP:$(PDFname)
 		
 		variable i
 
 		string /g currentDev,namefile
		string wavesL=wavelist("C*wave",";","")

		string ProtocolsList,  thewavelist,DIOlist
		ProtocolsList="";thewavelist="",DIOlist=""
		string DioClock="/"+currentDev+"/ai/SampleClock"

		For (i=0;i<(itemsinlist(wavesL));i=i+1)				
		string  TT=stringfromlist(i ,wavesL,";")
		TT=TT[1]
		Controlinfo /W=LTP $("p"+TT)
		string ProtocolinputWave=("C"+TT+"_"+S_value)
		Make /O /N=(numpnts(root:cLTP:protocols:$(S_value):$(S_value))) root:cLTP:$(PDFname):$(ProtocolinputWave)
		SetScale/P x, 0,(1/fmuestreo), "s" root:cLTP:$(PDFname):$(ProtocolinputWave)
		thewavelist=thewavelist+ProtocolinputWave+ ", "
		
			if (i==0)
			string  protocol1=S_value
			endif
			if (i==1)
			string  protocol2=S_value
			endif
			if (i==2)
			string  protocol3=S_value
			endif
			if (i==3)
			string  protocol4=S_value
			endif
		 
		variable /G $("C"+TT+"i")
		Nvar CiT= $("C"+TT+"i")
		variable /G $("C"+TT+"DIO")
		Nvar CDioT= $("C"+TT+"DIO")
		DioList=DioList+"/"+currentDev+"/port"+num2str(CurrDIOport)+"/line"+num2str(CDioT)+","
		thewavelist=thewavelist+num2str(CiT)+"/"+modeCv+","+"-"+RangeCv+","+RangeCv+";"
		endfor
		DioList=removeending(DioList)
		TheWaveList=removeending(TheWaveList)
		
		setdatafolder root:cLTP:$(PDFname):
		variable z=1
		string wavelist2save=wavelist("C*",";","")
		variable test=numpnts($(stringfromlist(0,wavelist2save,";")))
			Do
			if (test!=numpnts($(stringfromlist(z,wavelist2save,";"))) && itemsinlist(wavelist2save)>1)	
			execute "Acquire(thewavelist)"
			Doalert 0, "Protocols of different length cannot be used at the same time"
			abort
			endif
			z=z+1
			While (z<itemsinlist(wavelist2save))
					   
		setdatafolder root:cLTP:protocols:
		if (itemsinlist(thewavelist,";")==1)
		Duplicate /o root:cLTP:protocols:$(protocol1):$(protocol1), root:cLTP:$(PDFname):$(protocol1)
		setdatafolder root:cLTP:$(PDFname):
		DAQmx_DIO_Config   /CLK={DioClock,1} /Dev=currentDev /DIR=1 /LGRP = 1  /Wave={$(protocol1)} DioList
		endif
		if (itemsinlist(thewavelist,";")==2)
		Duplicate /o root:cLTP:protocols:$(protocol1):$(protocol1), root:cLTP:$(PDFname):$(protocol1)
		Duplicate /o root:cLTP:protocols:$(protocol2):$(protocol2), root:cLTP:$(PDFname):$(protocol2)
		setdatafolder root:cLTP:$(PDFname):
		DAQmx_DIO_Config   /CLK={DioClock,1} /Dev=currentDev /DIR=1 /LGRP = 1  /Wave={$(protocol1),$(protocol2)} DioList			
		endif
		if (itemsinlist(thewavelist,";")==3)
		Duplicate /o root:cLTP:protocols:$(protocol1):$(protocol1), root:cLTP:$(PDFname):$(protocol1)
		Duplicate /o root:cLTP:protocols:$(protocol2):$(protocol2), root:cLTP:$(PDFname):$(protocol2)
		Duplicate /o root:cLTP:protocols:$(protocol3):$(protocol3), root:cLTP:$(PDFname):$(protocol3)
		setdatafolder root:cLTP:$(PDFname):
		DAQmx_DIO_Config   /CLK={DioClock,1} /Dev=currentDev /DIR=1 /LGRP = 1  /Wave={$(protocol1),$(protocol2),$(protocol3)} DioList
		endif
		if (itemsinlist(thewavelist,";")==4)
		Duplicate /o root:cLTP:protocols:$(protocol1):$(protocol1), root:cLTP:$(PDFname):$(protocol1)
		Duplicate /o root:cLTP:protocols:$(protocol2):$(protocol2), root:cLTP:$(PDFname):$(protocol2)
		Duplicate /o root:cLTP:protocols:$(protocol3):$(protocol3), root:cLTP:$(PDFname):$(protocol3)
		Duplicate /o root:cLTP:protocols:$(protocol4):$(protocol4), root:cLTP:$(PDFname):$(protocol4)
		setdatafolder root:cLTP:$(PDFname):
		DAQmx_DIO_Config   /CLK={DioClock,1} /Dev=currentDev /DIR=1 /LGRP = 1  /Wave={$(protocol1),$(protocol2),$(protocol3),$(protocol4)} DioList
		endif
		
			
		string AOlist
		Controlinfo Aoselect
			if (cmpstr(s_value,"No Protocol")!=0)
			setdatafolder root:cLTP:protocols:$(s_value):
		
			if  (stringmatch(wavelist("*AO*",";",""),"*AO0*")==1)
			AOlist=Stringfromlist(0,wavelist("*AO0*",";",""))+", 0, -"+RangeCv+", "+RangeCv+";"
			duplicate /o $(Stringfromlist(0,wavelist("*AO0*",";",""))), root:cLTP:$(PDFname):$(Stringfromlist(0,wavelist("*AO0*",";","")))
			endif
			if  (stringmatch("*AO1*",wavelist("*AO*",";",""))==1)
			AOlist=AOlist+Stringfromlist(0,wavelist("*AO1*",";",""))+", 1, -"+RangeCv+", "+RangeCv+";"
			duplicate /o $(Stringfromlist(0,wavelist("*AO1*",";",""))), root:cLTP:$(PDFname): $(Stringfromlist(0,wavelist("*AO1*",";","")))
			endif
			endif
		setdatafolder root:cLTP:$(PDFname):
		if (strlen(AOList)>1)
		DAQmx_waveformgen /TRIG={"/dev1/ai/starttrigger"} /DEV=currentDev AOlist
		endif
		
		i=0
		do
		variable top=str2num(StringByKey(("C"+num2str(i+1))+"T", CCoord  , "=", ";") )
		variable bottom=str2num(StringByKey(("C"+num2str(i+1))+"B", CCoord  , "=", ";") )
		string color=(StringByKey(("C"+num2str(i+1)), ColorList  , "=", ";") )
	
				display /M /W=(0,(top),8,(bottom)) $(stringfromlist(i,wavelist2save,";"))
				i=i+1
		modifygraph lsize=1.5 , rgb=((str2num(stringfromlist(0,color,","))),(str2num(stringfromlist(1,color,","))),(str2num(stringfromlist(2,color,",")))) 
		while (i<itemsinlist(wavelist2save,";"))
	
		DAQmx_Scan /DEV=currentDev /EOSH="stop(num2str(0));setdatafolder root:cLTP;Acquire(thewavelist);activatebuttons()"/BKG WAVES=(TheWaveList)
		Dowindow /F LTP
		Button RunProtocolG,disable=1
		Button RunProtocol1,disable=1
		Button RunProtocol2,disable=1
		Button RunProtocol3,disable=1
		Button RunProtocol4,disable=1
		Button test1,disable=1
		Button test2,disable=1
		Button test3,disable=1
		Button test4,disable=1
		checkbox C1,disable=1
		checkbox C2,disable=1
		checkbox C3,disable=1
		checkbox C4,disable=1

		setdatafolder root:		
end

//////////////////////////////////////////////////
Function Runprotocoli(RunProtocol) : ButtonControl
string runprotocol

string /G currentdev
setdatafolder root:cLTP
 string TT2=RunProtocol[11]
if (waveexists($("C"+TT2+"wave"))==0)
Doalert 0,"Select at least one channel to run the protocol"
abort
endif

string /g CCoord,colorlist
 fDAQmx_ScanStop(currentdev)
 fDAQmx_ResetDevice(currentdev)
 CtrlNamedBackground _all_, stop
 	Controlinfo /W=LTP ModeC
	string modeCv=s_value
	Controlinfo  /W=LTP  RangeC
	string RangeCv=s_value
		
 		variable /G CurrDIOport,Valtmpo,fmuestreo
 		string PDFname="Protocol_at_"+num2str(Valtmpo)
 		newdatafolder /o root:CLTP:$(PDFname) 
 		string /g currentDev,namefile
		string ProtocolsList,  thewavelist,DIOlist
		ProtocolsList="";thewavelist="",DIOlist=""
		string DioClock="/"+currentDev+"/ai/SampleClock"
		string ProtocolinputWave2=("C"+TT2+"_"+S_value)
		Controlinfo /W=LTP $("p"+TT2)
		string Indprotocol=S_value
		Make /O /N=(numpnts(root:cLTP:protocols:$(S_value):$(S_value))) root:cLTP:$(PDFname):$(ProtocolinputWave2)
		SetScale/P x, 0,(1/fmuestreo), "s" root:cLTP:$(PDFname):$(ProtocolinputWave2)
		thewavelist=ProtocolinputWave2+ ", "
		variable /G $("C"+TT2+"i")
		Nvar CiT= $("C"+TT2+"i")
		variable /G $("C"+TT2+"DIO")
		Nvar CDioT= $("C"+TT2+"DIO")
		DioList=DioList+"/"+currentDev+"/port"+num2str(CurrDIOport)+"/line"+num2str(CDioT)+","
		thewavelist=thewavelist+num2str(CiT)+"/"+modeCv+","+"-"+RangeCv+","+RangeCv+";"
		
		DioList=removeending(DioList)
		TheWaveList=removeending(TheWaveList)
		setdatafolder root:cLTP:$(PDFname):
		variable z=1
		string wavelist2save=wavelist("C*",";","")
					   
		setdatafolder root:cLTP:protocols:
		Duplicate /o root:cLTP:protocols:$(Indprotocol):$(Indprotocol), root:cLTP:$(PDFname):$(Indprotocol)
		setdatafolder root:cLTP:$(PDFname):
		DAQmx_DIO_Config   /CLK={DioClock,1} /Dev=currentDev /DIR=1 /LGRP = 1  /Wave={$(Indprotocol)} DioList
			
		string AOlist
		Controlinfo Aoselect
			if (cmpstr(s_value,"No Protocol")!=0)
			setdatafolder root:cLTP:protocols:$(s_value):
		
				if  (stringmatch(wavelist("*AO*",";",""),"*AO0*")==1)
				AOlist=Stringfromlist(0,wavelist("*AO0*",";",""))+", 0, -"+RangeCv+", "+RangeCv+";"
				duplicate /o $(Stringfromlist(0,wavelist("*AO0*",";",""))), root:cLTP:$(PDFname):$(Stringfromlist(0,wavelist("*AO0*",";","")))
				endif
				if  (stringmatch("*AO1*",wavelist("*AO*",";",""))==1)
				AOlist=AOlist+Stringfromlist(0,wavelist("*AO1*",";",""))+", 1, -"+RangeCv+", "+RangeCv+";"
				duplicate /o $(Stringfromlist(0,wavelist("*AO1*",";",""))), root:cLTP:$(PDFname): $(Stringfromlist(0,wavelist("*AO1*",";","")))
				endif
				DAQmx_waveformgen /TRIG={"/dev1/ai/starttrigger"} /DEV=currentDev AOlist
			endif
		
		
		variable top=str2num(StringByKey(("C"+TT2+"T"), CCoord  , "=", ";") )
		variable bottom=str2num(StringByKey(("C"+(TT2)+"B"), CCoord  , "=", ";") )
		string color=(StringByKey(("C"+(TT2)), ColorList  , "=", ";") )
			display /M /W=(0,(top),8,(bottom)) $(stringfromlist(0,wavelist2save,";"))
				modifygraph lsize=1.5 , rgb=((str2num(stringfromlist(0,color,","))),(str2num(stringfromlist(1,color,","))),(str2num(stringfromlist(2,color,",")))) 	
		DAQmx_Scan /DEV=currentDev /EOSH="stop(num2str(0));setdatafolder root:cLTP;Acquire(thewavelist);activatebuttons()"/BKG WAVES=(TheWaveList)
		Dowindow /F LTP
		Button RunProtocolG,disable=2
		Button RunProtocol1,disable=2
		Button RunProtocol2,disable=2
		Button RunProtocol3,disable=2
		Button RunProtocol4,disable=2
		Button test1,disable=2
		Button test2,disable=2
		Button test3,disable=2
		Button test4,disable=2
		checkbox C1,disable=2
		checkbox C2,disable=2
		checkbox C3,disable=2
		checkbox C4,disable=2
		setdatafolder root:

end
		//////////////////////////////////////////////	
		
function record()  
								/////L counts the number of averages made... therefore the number of points in the graphs

setdatafolder root:cltp
variable /g recordcheck

if (recordcheck==0)
abort
endif

string /g  thewavelist ,namefile,TwlistG
variable/g J,L,n,Valtmpo,delayedstim
variable i=0;	

		Do	
		if (delayedstim==1)
		thewavelist=TwlistG
		endif
		string Channel=stringfromlist(i,thewavelist,";")
		Channel=Channel[0,1]
		wave temp= $(Channel+"Temp")
		wave  tempAvg= $(Channel+"TempAvg")
		J=numpnts(temp)
		timer(channel)
		if (j==0)
		redimension /n=(numpnts(temp)+1) temp 
		endif
		L=floor((J)/n)+1
		
		wave Rwave=$(Channel+"wave")
		wave Awave=$(Channel+"wave_Avg")
		wave TAwave=$(Channel+"wave_AvgT")
		Duplicate /o Rwave, root:cLTP:Raw_Sweeps:$(namefile):$(Channel):$(Channel+"_"+num2str(J))
		TAwave=TAwave+Rwave
		if (J+1>=n*l)
		TAwave=TAwave/n
		Awave=TAwave
		Duplicate /o TAwave, root:cLTP:Averaged_Sweeps:$(namefile):$(Channel):$(Channel+"_"+num2str(L))
		redimension /n=(L) tempAvg
		tempAvg[L]=Valtmpo
		TAwave=0
		OLAnalysis(Channel)
		Savetodisk(Channel)
		endif
		i=i+1
		While (i<itemsinlist(thewavelist,";"))
setdatafolder root:
end

/////////////////////////////////////
function timer(channel)
string channel

setdatafolder root:cLTP
variable hr,mins,seg
Variable /G Valtmpo,  Valtmpoi, j
String Tmpo
wave temp= $(Channel+"Temp")

If (Valtmpoi!=0 && j!=0)
redimension /n=(numpnts(temp)+1) temp 
tmpo=time()
sscanf tmpo,"%d%*[:]%d%*[:]%d",hr,mins,seg
Valtmpo=(((hr*60+mins)*60)+(seg)-1) 
Valtmpo=(Valtmpo-Valtmpoi)/60	
//print time(),hr,mins,seg,Valtmpo

temp[numpnts(temp)-1]=(Valtmpo)
endif
end

//////////////////////////////////////////////
Function OLAnalysis(Channel)   /////Cursors square-circle measure the baseline
string channel							//////Cursors C-E measure the peak and area
							//////Cursors C-d measure slope by fitting a line
variable /G Npeak				////Half width is looked by looking at half amplitude between C and D and later from D and E
variable baseline,level1
setdatafolder root:cLTP:
variable /G L
wave TolaWave=$(Channel+"wave_Avg")
wave Amp=$(Channel+"_Amp")
wave A2=$(Channel+"_Area")
wave HW=$(Channel+"_HalfWidth")
wave Slope=$(Channel+"_Slope")
 if (L!=1)
redimension /n=(numpnts(Amp)+1) Amp ,A2,HW,Slope
endif

Dowindow $(Channel+"0")
if (v_flag==1)
baseline=(mean(TolaWave, xcsr(A, (Channel+"0")),xcsr(B, (Channel+"0"))))
Duplicate /free TolaWave, AbsW
AbsW=AbsW-baseline
AbsW=Sqrt(AbsW*AbsW)
A2[L]=area(AbsW,xcsr(C, (Channel+"0")),xcsr(E, (Channel+"0")))

if (Npeak==1)
Amp[L]= wavemin(TolaWave,xcsr(C, (Channel+"0")),xcsr(E, (Channel+"0")))-(baseline)
endif
if (Npeak==0)
Amp[L]= wavemax(TolaWave,xcsr(C, (Channel+"0")),xcsr(E, (Channel+"0")))-(baseline)
endif

Curvefit /N/Q line TolaWave[pcsr(C, (Channel+"0")),pcsr(D, (Channel+"0"))]  /D
wave W_coef

if (strsearch(tracenamelist((Channel+"_Avg"), ";", 1),("fit_"+Channel+"wave_Avg"),0)==-1)
	Dowindow $(Channel+"_Avg")
	if (v_flag==1)
Appendtograph /W=$(Channel+"_Avg") $("fit_"+Channel+"wave_Avg")
endif
endif

Slope[L]=w_coef[1]

Findlevel /R=(xcsr(C, (Channel+"0")),xcsr(D, (Channel+"0"))) /q TolaWave, (Amp[L-1]*.5-baseline)
level1=v_levelx
Findlevel /R=(xcsr(D, (Channel+"0")),xcsr(E, (Channel+"0"))) /q TolaWave, (Amp[L-1]*.5-baseline)
HW[L]=v_levelx-level1
else 
HW[L]=Nan
Amp[L]=Nan
A2[L]=Nan
Slope[L]=Nan
endif
setdatafolder root: 
end

//////////////////////////////////////////////////
function carpeta(carpeta): buttoncontrol
string carpeta
Newpath /O/C/Z Path1 
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function reset(detener): Buttoncontrol
string detener

Doalert /T="Continue reset?" 1, "Continuing will eliminate all your non saved data"
	if (v_flag==2)
	abort
	endif
	
setdatafolder root:cLTP
Variable/G j,Valtmpo,ValtmpoI,tmpoIset,k,L
string /g namefile
 fDAQmx_WaveformStop("dev1")
fDAQmx_ScanStop("dev1")
 fDAQmx_ResetDevice("dev1")
  CtrlNamedBackground _all_, stop
 Dowindow /K HalfWidth
 Dowindow /K AreaD
 Dowindow /K Slope
  Dowindow /K Amp
 j=0;k=0;L=1
Valtmpo=0;ValtmpoI=0
Variable/G numTraces		//BG edit 18Dec19
numTraces = 0 			//BG edit 18Dec19
if (waveexists(C1temp)==1)
redimension /N=0  C1temp
endif
if (waveexists(C2temp)==1)
redimension /N=0  C2temp
endif
if (waveexists(C3temp)==1)
redimension /N=0  C3temp
endif
if (waveexists(C4temp)==1)
redimension /N=0  C4temp
endif
string DFs="root:cLTP:raw_sweeps:'"+namefile+"':C1" 

if (datafolderexists(DFs)==1)
setdatafolder root:cLTP:raw_sweeps:$(namefile):C1
Killwaves /a /z 
setdatafolder root:cLTP:averaged_sweeps:$(namefile):C1
Killwaves /a /z 
setdatafolder root:cLTP
WaveInit ("C1",0) 
WaveInit ("C1",1) 
endif

 DFs="root:cLTP:raw_sweeps:'"+namefile+"':C2" 
if (datafolderexists(DFs)==1)
setdatafolder root:cLTP:raw_sweeps:$(namefile):C2
Killwaves /a /z 
setdatafolder root:cLTP:averaged_sweeps:$(namefile):C2
Killwaves /a /z 
setdatafolder root:cLTP
WaveInit ("C2",0) 
WaveInit ("C2",1) 
endif

 DFs="root:cLTP:raw_sweeps:'"+namefile+"':C3" 
if (datafolderexists(DFs)==1)
setdatafolder root:cLTP:raw_sweeps:$(namefile):C3
Killwaves /a /z 
setdatafolder root:cLTP:averaged_sweeps:$(namefile):C3
Killwaves /a /z 
setdatafolder root:cLTP
WaveInit ("C3",0) 
WaveInit ("C3",1) 
endif

 DFs="root:cLTP:raw_sweeps:'"+namefile+"':C4" 
if (datafolderexists(DFs)==1)
setdatafolder root:cLTP:raw_sweeps:$(namefile):C4
Killwaves /a /z 
setdatafolder root:cLTP:averaged_sweeps:$(namefile):C4
Killwaves /a /z 
setdatafolder root:cLTP
WaveInit ("C4",0) 
WaveInit ("C4",1) 
endif
	dowindow /F LTP
	Button RunProtocolG,disable=0
	Button RunProtocol1,disable=0
	Button RunProtocol2,disable=0
	Button RunProtocol3,disable=0
	Button RunProtocol4,disable=0
	Button test1,disable=0
		Button test2,disable=0
		Button test3,disable=0
		Button test4,disable=0
		checkbox C1,disable=0
		checkbox C2,disable=0
		checkbox C3,disable=0
		checkbox C4,disable=0
Button Ad,win=ltp, disable=0
setdatafolder root:
end

/////////////////////////////////////////////////////////////////////////////
Function reviewPrt(Protocolo) : ButtonControl
String Protocolo

setdatafolder root:cLTP
VARIABLE/g TotalProtduration,durraf,durpulso,Fmuestreo,Numpulsos,frecpulsos,numrafagas,frecrafagas,numtrenes,frectrenes,DistpPProtocol,Pdelay,durtren

make/B/U/O/N=((1/frecpulsos)*fmuestreo*numpulsos) rafaga
SetScale/p x, 0,(1/fmuestreo), "s", rafaga

Controlinfo /W=LTP Protocolos
	if (cmpstr(S_Value,"New protocol")==0 || cmpstr(S_Value,"No protocol")==0)

		Variable h=0
		ControlInfo PpareadoProtocol
		If (V_value==1)
		Do
		Rafaga[x2pnt(Rafaga,(Pdelay/1000)+h*(1/frecpulsos)),x2pnt(Rafaga,(Pdelay/1000)+(durpulso/1000)+(h*(1/frecpulsos)))]=1
		Rafaga[x2pnt(Rafaga,(Pdelay/1000)+h*(1/frecpulsos)+(DistpPProtocol/1000)),x2pnt(Rafaga,0.005+(durpulso/1000)+(h*(1/frecpulsos))+(DistpPProtocol/1000))]=1
		h=h+1
		while (h<numpulsos)
 
		endif
		Do
		Rafaga[x2pnt(Rafaga,(Pdelay/1000)+h*(1/frecpulsos)),x2pnt(Rafaga,(Pdelay/1000)+(durpulso/1000)+(h*(1/frecpulsos)))]=1
		h=h+1
		while (h<numpulsos)
 
 
		if (numrafagas>1)
		durraf=((1/Frecrafagas)*Fmuestreo)
		make/B/U/O/N=(durraf*numrafagas) trentemp
		trentemp=rafaga

		h=1
		Do
		trentemp[durraf*h,durraf*(h+1)]=rafaga[p-durraf*h]
		h=h+1
		While (h<numrafagas)
		SetScale/p x, 0,(1/fmuestreo), "s", Trentemp
		elseif (numrafagas==1)
		Duplicate/O rafaga,trentemp
		endif

		if (numtrenes>1)
		durtren=((1/Frectrenes)*Fmuestreo)
		make/B/U/O/N=(durtren*numtrenes) Protocoltemp

		ProtocolTemp=Trentemp
		h=1
		Do
		protocoltemp[h*durtren,(h+1)*durtren]=Trentemp[p-h*durtren]
		h=h+1
		While (h<numtrenes)
		SetScale/p x, 0,(1/fmuestreo), "s", Protocoltemp
		elseif (numtrenes==1)
		duplicate/O trentemp,protocoltemp
		endif
		killwaves /z trentemp,rafaga
		if (TotalProtduration!=0)
		redimension /N=(TotalProtduration*Fmuestreo) Protocoltemp
		endif
		Display Protocoltemp
	elseif (cmpstr(S_Value,"New protocol")!=0)
		Display   root:cLTP:Protocols:$(S_Value):$(S_Value)
	endif
		setdatafolder root:
		end
//////////////////////////////////////////////////////////////////////////////////////////
Function SavePrt(SavePrt) : ButtonControl
String SavePrt

setdatafolder root:cLTP:

if (waveexists(protocoltemp)==0)
Doalert 0,  "No protocol created", 
abort
endif

String/ G  NombreProtocolo
if (strlen(NombreProtocolo)==0)
Doalert 0,  "Select a name for current protocol"
abort
endif

setdatafolder root:cLTP:protocols:
newdatafolder /o root:cLTP:protocols:$(NombreProtocolo)
Duplicate /O root:cltp:protocoltemp, root:cLtp:protocols:$(NombreProtocolo):$(NombreProtocolo)
SaveData/q/O/I /R
String /g ProtocolList= datafolderdir(1)
	String /g protocolList2

ProtocolList=ProtocolList[8,strlen(ProtocolList)-3]
protocolList=replacestring(",",protocolList, ";")
string /G AOProtocolList="No Protocol"
variable i
	Do
		setdatafolder root:cLTP:Protocols:$(stringfromlist(i,protocolList,";"))	
		if (stringmatch(Datafolderdir(2),"*AO*")==1)
			AOProtocolList=AOProtocolList+";"+(stringfromlist(i,protocolList,";"))
			endif
			i=i+1
			while (i<itemsinlist(ProtocolList))
	
	PopupMenu Protocolos WIN=LTP, value= #"root:cLTP:protocols:ProtocolList2"

	 protocolList2="New protocol;"+protocolList

PopupMenu p4 WIN=LTP, value= #"root:cLTP:protocols:ProtocolList"
PopupMenu p3 WIN=LTP, value= #"root:cLTP:protocols:ProtocolList"
PopupMenu p2 WIN=LTP, value= #"root:cLTP:protocols:ProtocolList"
PopupMenu p1 WIN=LTP, value= #"root:cLTP:protocols:ProtocolList"
PopupMenu AOselect, WIN=LTP, value= #"root:cLTP:protocols:AOProtocolList"
SetDatafolder Root:
end
//////////////////////////////////////////////////////////////////////////////////////////
Function LoadPrt(LoadPrt) : ButtonControl
String LoadPrt
setdatafolder root:cltp:protocols
Loaddata /o/q/r
String /g ProtocolList= datafolderdir(1)
ProtocolList=ProtocolList[8,strlen(ProtocolList)-3]
protocolList=replacestring(",",protocolList, ";")
	String /g protocolList2
PopupMenu Protocolos WIN=LTP, value= #"root:cLTP:protocols:ProtocolList2"
PopupMenu p4 WIN=LTP, value= #"root:cLTP:protocols:ProtocolList"
PopupMenu p3 WIN=LTP, value= #"root:cLTP:protocols:ProtocolList"
PopupMenu p2 WIN=LTP, value= #"root:cLTP:protocols:ProtocolList"
PopupMenu p1 WIN=LTP, value= #"root:cLTP:protocols:ProtocolList"
		string /G AOProtocolList="No Protocol"
		variable i
		Do
		setdatafolder root:cLTP:Protocols:$(stringfromlist(i,protocolList,";"))	
		if (stringmatch(Datafolderdir(2),"*AO*")==1)
			AOProtocolList=AOProtocolList+";"+(stringfromlist(i,protocolList,";"))
			endif
			i=i+1
			while (i<itemsinlist(ProtocolList))
		
			protocolList2="New protocol;"+protocolList

			PopupMenu AOselect, WIN=LTP, value= #"root:cLTP:protocols:AOProtocolList"


SetDatafolder Root:
end
////////////////////////////////////////////////////////////////////////////////////////////////////////
	Function DeletePrt(DeletePrt) : ButtonControl
String DeletePrt

setdatafolder root:cLTP:

if (waveexists(protocoltemp)==0)
Doalert 0,  "No protocol created", 
abort
endif

String/ G  NombreProtocolo
if (strlen(NombreProtocolo)==0)
Doalert 0,  "Select a name for current protocol"
abort
endif

setdatafolder root:cLTP:protocols:
Controlinfo /W=LTP Protocolos
killdatafolder   root:cLTP:protocols:$(s_value)

SaveData/q/O/I /R
String /g ProtocolList= datafolderdir(1)
	String /g protocolList2

ProtocolList=ProtocolList[8,strlen(ProtocolList)-3]
protocolList=replacestring(",",protocolList, ";")
string /G AOProtocolList="No Protocol"
variable i
	Do
		setdatafolder root:cLTP:Protocols:$(stringfromlist(i,protocolList,";"))	
		if (stringmatch(Datafolderdir(2),"*AO*")==1)
			AOProtocolList=AOProtocolList+";"+(stringfromlist(i,protocolList,";"))
			endif
			i=i+1
			while (i<itemsinlist(ProtocolList))
			
PopupMenu Protocolos WIN=LTP, value= #"root:cLTP:protocols:ProtocolList2"

	 protocolList2="New protocol;"+protocolList
	
PopupMenu p4 WIN=LTP, value= #"root:cLTP:protocols:ProtocolList"
PopupMenu p3 WIN=LTP, value= #"root:cLTP:protocols:ProtocolList"
PopupMenu p2 WIN=LTP, value= #"root:cLTP:protocols:ProtocolList"
PopupMenu p1 WIN=LTP, value= #"root:cLTP:protocols:ProtocolList"
PopupMenu AOselect, WIN=LTP, value= #"root:cLTP:protocols:AOProtocolList"
SetDatafolder Root:
end
	

//////////////////////////////////////////////////////////////////////////////////////////////////////////
Function WaveInit (Ctrlname,checked) :Checkboxcontrol
String Ctrlname
variable checked

Setdatafolder Root:cLTP:

string /G CCoord,ColorList
variable /g Sweeplength,fmuestreo,dur,n,ppcheck, C1i,C2i, C3i,C4i
string /G TheWaveList,namefile
string Kwindow 

string color=(StringByKey(("C"+(Ctrlname[1])), ColorList  , "=", ";") )
variable top=str2num(StringByKey(("C"+(Ctrlname[1])+"T"), CCoord  , "=", ";") )
variable bottom=str2num(StringByKey(("C"+(Ctrlname[1])+"B"), CCoord  , "=", ";") )
variable ctrlnamenumber=str2num(Ctrlname[1])
if (checked==0)
Dowindow /K $(Ctrlname+num2str(0))
Dowindow /K  $(Ctrlname+"_Avg")
killdatafolder /z root:cLTP:Raw_Sweeps:$(namefile):$(Ctrlname)
killdatafolder /z root:cLTP:Averaged_Sweeps:$(namefile):$(Ctrlname)
killwaves /z $(Ctrlname+"wave"), $(Ctrlname+"wave"+"_Avg"), $(Ctrlname+"wave"+"_AvgT"), $(Ctrlname+"_Slope"), $(Ctrlname+"_Halfwidth"),  $(Ctrlname+"_Amp"),  $(Ctrlname+"_Area")
killwaves /z $(Ctrlname+"_ppSlope"), $(Ctrlname+"_ppHalfwidth"),  $(Ctrlname+"_ppAmp"),  $(Ctrlname+"_ppArea"),$(Ctrlname+"temp"),$(Ctrlname+"tempAvg")
setdatafolder root:
return 0
endif

newdatafolder /O root:cLTP:Raw_Sweeps:$(namefile)
newdatafolder /O root:cLTP:Raw_Sweeps:$(namefile):$(Ctrlname)
newdatafolder /O root:cLTP:Averaged_Sweeps:$(namefile)
newdatafolder /O root:cLTP:Averaged_Sweeps:$(namefile):$(Ctrlname)

Make/O/N=((Sweeplength/1000)*fmuestreo) $(Ctrlname+"wave"), $(Ctrlname+"wave"+"_Avg"), $(Ctrlname+"wave"+"_AvgT")
SetScale/P x, 0,(1/fmuestreo), "s",  $(Ctrlname+"wave"), $(Ctrlname+"wave"+"_Avg"), $(Ctrlname+"wave"+"_AvgT")
make/O /N=(1) $(Ctrlname+"_Slope"), $(Ctrlname+"_Halfwidth"),  $(Ctrlname+"_Amp"),  $(Ctrlname+"_Area")
make /o/N=0 $(Ctrlname+"temp")
make /o/N=0 $(Ctrlname+"tempAvg")
	
	Dowindow $(Ctrlname+num2str(0))
	wave wav=root:cLTP:$(Ctrlname+"wave")
	wave Awave=root:cLtp:$(Ctrlname+"wave_Avg")
	if (V_flag==0)
	Dowindow $(Ctrlname)
	
	
		Display/K=2 /M/W=(0,(top),8,(bottom)) /N=$(Ctrlname) wav
		modifygraph  lblLatPos(left)=50,margin(top)=3,margin(right)=3,margin(bottom)=23,margin(left)=23,tick=1,lblMargin=5,ZisZ=1,zapTZ=1,zapLZ=1,lsize=1.5 , fsize=8,  rgb=((str2num(stringfromlist(0,color,","))),(str2num(stringfromlist(1,color,","))),(str2num(stringfromlist(2,color,",")))) 
		Cursor /H=0/p	/C=(0,65280,0)  A $(Ctrlname+"wave") (.1*(numpnts(wav)))
		Cursor  /H=0/p	/C=(0,65280,0)  B $(Ctrlname+"wave")  (.2*(numpnts(wav)))
		Cursor  /H=2/p	/C=(65280,16384,16384) C $(Ctrlname+"wave")  (.3*(numpnts(wav)))
		Cursor  /H=2/p	/C=(65280,16384,16384) D $(Ctrlname+"wave")  (.5*(numpnts(wav)))
		Cursor  /H=2/p	/C=(52224,0,0) E $(Ctrlname+"wave")  (.7*(numpnts(wav)))
		Label left "mV"
		Label bottom "\\u#2"
	Dowindow $(Ctrlname+"_Avg")
		Display/K=2 /M/W=(8.2,(top),16,(bottom)) /N=$(Ctrlname+"_Avg") Awave
		modifygraph lblLatPos(left)=50,margin(bottom)=23,margin(top)=3,margin(right)=3,margin(left)=23,tick=1, lblMargin=5,ZisZ=1,zapTZ=1,zapLZ=1,lsize=1.5 , fsize=8, rgb=((str2num(stringfromlist(0,color,","))),(str2num(stringfromlist(1,color,","))),(str2num(stringfromlist(2,color,",")))) 
		Label left "mV" 
		Label bottom "\\u#2"

		endif
	
	if (ppcheck==1)
	make/O /N=(1) $(Ctrlname+"_ppSlope"), $(Ctrlname+"_ppHalfwidth"),  $(Ctrlname+"_ppAmp"),  $(Ctrlname+"_ppArea")
	endif
	
setdatafolder root:
end

/////////////////////////////////////////////
Function Pulseinit (ctrlName,varNum,varStr,varName)  : SetvariableControl: SetVariableControl
String ctrlName
Variable varNum // value of variable as number
String varStr // value of variable as string
String varName // name of variable
setdatafolder root:cLTP:
variable /g Sweeplength,Pdelay1,Pdelay2,Pdelay3,Pdelay4, ppcheck,fmuestreo,durpulso,DistPp

variable i=1
Do
Nvar delay=$("PDdelay"+num2str(i))
make/B/U/O/N=((Sweeplength/1000)*fmuestreo) Root:cLTP:$("Pulse"+num2str(i)) /Wave=Pulse
pulse=0
 SetScale/p x, 0,(1/fmuestreo), "s", Pulse;
Pulse[x2pnt(Pulse,delay/1000),x2pnt(Pulse,((delay/1000)+(durpulso/1000)))]=1
	
	if (DistpP!=0)
	Pulse[x2pnt(Pulse,delay/1000),x2pnt(Pulse,delay/1000+(Durpulso/1000))]=1
	Pulse[x2pnt(Pulse,(DistPp/1000+delay/1000)),x2pnt(Pulse,(DistPp/1000+delay/1000+Durpulso/1000))]=1
	endif   
	
i=i+1
while (i<5)
	setdatafolder root:
	

End

//////////////////////////////////////////////////
Function Test (str) : ButtonControl
string str

setdatafolder root:cltp
//execute "stop(num2str(0))"
Variable /G C1, C2, C3, C4,sweeplength
string ChannelsList=""
string str2="*C"+(str[4])+"*"	
	string /G currentDev
	VARIABLE/G  CurrDIOport,dur,C1, C2,C3,C4,C1DIO,C2DIO,C3DIO,C4DIO
	//Variable numTicks = dur * 60 
	Controlinfo /W=LTP ModeC
	string modeCv=s_value
	Controlinfo  /W=LTP  RangeC
	string RangeCv=s_value
	
	if (C1==1)
	ChannelsList=ChannelsList+"C1;"
	endif
	if 	(C2==1)
	ChannelsList=ChannelsList+"C2;"
	endif
	if 	(C3==1)
	ChannelsList=ChannelsList+"C3;"
	endif
	if 	(C4==1)
	ChannelsList=ChannelsList+"C4;"
	endif 
	
	if (stringmatch(ChannelsList, str2)==0)
	Doalert /T="Error found" 0,"Channel not selected"
	abort
	endif
	
	wave pulse=root:cLTP:pulse
	wave wav=root:cLTP:$("C"+str[4]+"wave")

		variable /G $("C"+(str[4])+"i")
		Nvar CiT= $("C"+(str[4])+"i")
		variable /G $("C"+(str[4])+"DIO")
		Nvar CDioT= $("C"+(str[4])+"DIO")
		string DioS="/"+currentDev+"/port"+num2str(CurrDIOport)+"/line"+num2str(CDioT)+","
		string WaveandInputCh= "C"+(str[4])+"wave,"+num2str(CiT)+"/"+modeCv+","+"-"+RangeCv+","+RangeCv+";"
		string Npulse="pulse"+str[4]
		DioS=removeending(Dios)
		string DioClock="/"+currentDev+"/ai/SampleClock"
	DAQmx_DIO_Config  /CLK={DioClock,1} /Dev=currentDev /DIR=1 /LGRP = 1  /Wave={$(NPulse)} DioS
	
	if (GetRTError(1)) // 1 to clear error and continue execution
print "Error starting DIO operation"
print fDAQmx_ErrorString()
endif

	DAQmx_Scan /DEV=currentDev /EOSH="stop(num2str(0))" /BKG  	WAVES=WaveandInputCh
	if (GetRTError(1)) // 1 to clear error and continue execution
print "Error starting scanning operation"
print fDAQmx_ErrorString()
endif
	setdatafolder root:
	
	end
///////////////////////////////////////////
Function AmpDisplay(str) : ButtonControl
string str
variable i

setdatafolder root:cLTP
Dowindow Amp
if (v_flag==1 || strlen(wavelist("*tempAvg",";",""))==0)
Dowindow /K Amp
abort
ENDIF 

string List=Wavelist("*Amp*",";","")

Display /M /W=(16.5,1,26,6) /N=Amp as "Maximum Amplitude"
string /G ColorList,MarkerList
modifygraph  margin(top)=3,margin(right)=3,margin(bottom)=23,margin(left)=23,tick=1,lblMargin=5,ZisZ=1,zapTZ=1,zapLZ=1,lsize=1.5 , fsize=8

Do	
string TAw=(stringfromlist(i,List,";"))
string color=(StringByKey(TAw[0,1], ColorList  , "=", ";"))
string marker=(StringByKey(TAw[0,1], MarkerList  , "=", ";"))
Appendtograph $(TAw) vs $(TAw[0,1]+"tempAvg")
modifygraph rgb($TaW)=((str2num(stringfromlist(0,color,","))),(str2num(stringfromlist(1,color,","))),(str2num(stringfromlist(2,color,",")))) 
modifygraph mode($TaW)=4, msize($TaW)=3, marker($TaW)=(str2num(marker))
i=i+1
While (i<itemsinlist(List))
end

//////////////////////////////////////////////////////////
Function SlopeDisplay(str) : ButtonControl
string str
variable i
setdatafolder root:cLTP
Dowindow Slope
if (v_flag==1 || strlen(wavelist("*tempAvg",";",""))==0)
Dowindow /K Slope
abort
ENDIF 

string List=Wavelist("*Slope*",";","")
Display /M /W=(16.5,6.5,26,11.5) /N=Slope as "Max Slope"
modifygraph  margin(top)=3,margin(right)=3,margin(bottom)=23,margin(left)=23,tick=1,lblMargin=5,ZisZ=1,zapTZ=1,zapLZ=1,lsize=1.5 , fsize=8
string /G ColorList,MarkerList
	

Do	
string TAw=(stringfromlist(i,List,";"))
string color=(StringByKey(TAw[0,1], ColorList  , "=", ";"))
string marker=(StringByKey(TAw[0,1], MarkerList  , "=", ";"))
Appendtograph $(TAw) vs $(TAw[0,1]+"tempAvg")
modifygraph rgb($TaW)=((str2num(stringfromlist(0,color,","))),(str2num(stringfromlist(1,color,","))),(str2num(stringfromlist(2,color,",")))) 
modifygraph mode($TaW)=4, msize($TaW)=3, marker($TaW)=(str2num(marker))
i=i+1
While (i<itemsinlist(List))
setdatafolder root:
end
/////////////////////////////////////////////////////////////////////
Function AreaDisplay(str) : ButtonControl
string str
variable i
setdatafolder root:cLTP
Dowindow AreaD
if (v_flag==1 || strlen(wavelist("*tempAvg",";",""))==0)
Dowindow /K AreaD
abort
ENDIF 

string List=Wavelist("*Area*",";","")
Display /M /W=(16.5,12,26,17)/N=AreaD as "Area"
modifygraph  margin(top)=3,margin(right)=3,margin(bottom)=23,margin(left)=23,tick=1,lblMargin=5,ZisZ=1,zapTZ=1,zapLZ=1,lsize=1.5 , fsize=8
string /G ColorList,MarkerList

Do	
string TAw=(stringfromlist(i,List,";"))
string color=(StringByKey(TAw[0,1], ColorList  , "=", ";"))
string marker=(StringByKey(TAw[0,1], MarkerList  , "=", ";"))
Appendtograph $(TAw) vs $(TAw[0,1]+"tempAvg")
modifygraph rgb($TaW)=((str2num(stringfromlist(0,color,","))),(str2num(stringfromlist(1,color,","))),(str2num(stringfromlist(2,color,",")))) 
modifygraph mode($TaW)=4, msize($TaW)=3, marker($TaW)=(str2num(marker))
i=i+1
While (i<itemsinlist(List))
setdatafolder root:
end
/////////////////////////////////////////////////////////////////////
Function HFDisplay(str) : ButtonControl
string str
variable i
setdatafolder root:cLTP
Dowindow HalfWidth

if (v_flag==1 || strlen(wavelist("*tempAvg",";",""))==0)
Dowindow /K HalfWidth
abort
ENDIF 

string List=Wavelist("*HalfWidth*",";","")

Display /M /W=(19,1,29.5,6) /N=HalfWidth as "Half Width"
modifygraph  margin(top)=3,margin(right)=3,margin(bottom)=23,margin(left)=23,tick=1,lblMargin=5,ZisZ=1,zapTZ=1,zapLZ=1,lsize=1.5 , fsize=8

string /G ColorList,MarkerList
Do	
string TAw=(stringfromlist(i,List,";"))
string color=(StringByKey(TAw[0,1], ColorList  , "=", ";"))
string marker=(StringByKey(TAw[0,1], MarkerList  , "=", ";"))
Appendtograph $(TAw) vs $(TAw[0,1]+"tempAvg")
modifygraph rgb($TaW)=((str2num(stringfromlist(0,color,","))),(str2num(stringfromlist(1,color,","))),(str2num(stringfromlist(2,color,",")))) 
modifygraph mode($TaW)=4, msize($TaW)=3, marker($TaW)=(str2num(marker))
i=i+1
While (i<itemsinlist(List))
setdatafolder root:
end

//////////////////////////////////////////////////////////////
Function AddAOCW(Ctrlname) : ButtonControl
string Ctrlname
Setdatafolder root:cLTP
string /G Nombreprotocolo
variable /g fmuestreo
string AOfilename
string AOnumber
Prompt AOfilename, "Enter full igor path of selected file"
Prompt AOnumber,  "Select tha analog output channel", popup, "0;1"
Doprompt "Select a file for analog output stimulation", AOfilename, AOnumber

if (v_flag==1)
abort
endif

if (datafolderexists("root:cLTP:protocols:"+Nombreprotocolo)==0 || numpnts($(AOfilename))!= numpnts(root:cLTP:protocols:$(Nombreprotocolo):$(Nombreprotocolo)))
Doalert 0,"There is no current DIO protocol to add an DAO waveform to or number of points is different"
abort
endif

Duplicate /o $(AOfilename), Root:cLTP:protocols:$(Nombreprotocolo):$(Nombreprotocolo+"AO"+AOnumber)
wave input= Root:cLTP:protocols:$(Nombreprotocolo):$(Nombreprotocolo+"AO"+AOnumber)
SetScale/P x, 0,(1/fmuestreo), "s" input
setdatafolder root:
end
//////////////////////////////////////////////
Function AddDIOCW(Ctrlname) : ButtonControl
string Ctrlname
Setdatafolder root:cLTP
string /G Nombreprotocolo
variable /g fmuestreo
string DIOfilename
Prompt DIOfilename, "Enter full igor path of selected file"
Doprompt "Select a file for DIGITAL output stimulation", DIOfilename

if (wavetype($(DIOfilename))!=72)
Redimension/B $(DIOfilename)
endif


Duplicate /o $(DIOfilename), protocoltemp
SetScale/P x, 0,(1/fmuestreo), "s" input
setdatafolder root:
end

////////////////////////////////////////////////////////
Function OscDisp(Mostrar) : ButtonControl
string mostrar

Dowindow Oscilloscope 

if (v_flag!=0)
abort
endif 
Setdatafolder root:cLTP

Variable/G  Timewindow,fmuestreo,C1i,C2i, C3i,C4i
timewindow=100

	NewPanel /k=2 /M /N=Oscilloscope /W=(1,1,20,15)
	ShowTools/A
	SetDrawLayer UserBack
	SetDrawEnv fname= "Calibri",fsize= 15,fstyle= 1
	DrawText 28,23,"Channel 1 "
	SetDrawEnv fname= "Calibri",fsize= 15,fstyle= 1
	DrawText 28,252,"Channel 3"
	SetDrawEnv fname= "Calibri",fsize= 15,fstyle= 1
	DrawText 368,251,"Channel 4"
	SetDrawEnv fname= "Calibri",fsize= 15,fstyle= 1
	DrawText 370,23,"Channel 2"
	SetVariable Timewindow,pos={32,484},size={220,21},title="Time/Display (msecs)",font="Calibri",fSize=13,proc=OscTimeWindow
	SetVariable Timewindow,limits={1,10000,10},value= Timewindow,live= 1
	Button CloseOsc,pos={580,477},size={100,30},title="Close",font="Calibri"
	Button CloseOsc,fSize=13	, proc=CloseOsc
	
	Make /O /N=((Timewindow/1000)*fmuestreo) Channel1Osc
	 SetScale/P x, 0,(1/fmuestreo), "s", Channel1Osc
	Make /O /N=((Timewindow/1000)*fmuestreo) Channel2Osc
	 SetScale/P x, 0,(1/fmuestreo), "s", Channel2Osc
	Make /O /N=((Timewindow/1000)*fmuestreo) Channel3Osc
	 SetScale/P x, 0,(1/fmuestreo), "s", Channel3Osc
	Make /O /N=((Timewindow/1000)*fmuestreo) Channel4Osc
	 SetScale/P x, 0,(1/fmuestreo), "s", Channel4Osc

	Display /N=Channel1_Osc /M /W=(1,1,12,8)  /hOST= Oscilloscope Channel1Osc
	Display /N=Channel2_Osc /M /W=(13,1,24,8)  /hOST= Oscilloscope Channel2Osc
	Display /N=Channel3_Osc /M /W=(1,9,12,16)  /hOST= Oscilloscope Channel3Osc
	Display /N=Channel4_Osc /M /W=(13,9,24,16)  /hOST= Oscilloscope Channel4Osc
	 	

	 String OscList="Channel1Osc, "+num2str(C1i)+";"+"Channel2Osc, "+num2str(C2i)+";"+"Channel3Osc, "+num2str(C3i)+";"+"Channel4Osc, "+num2str(C4i)+";"
	DAQmx_Scan /DEV="dev1" /BKG /RPTC 	WAVES=OscList
	Setdatafolder root:
	OscTimeWindow("Timewindow",.1,".1","Timewindow") 
	pauseforuser Oscilloscope
end
//////////////////////////////////////////////
Function CloseOsc(str) : Buttoncontrol
String str

 fDAQmx_WaveformStop("dev1")
 fDAQmx_ScanStop("dev1")
 fDAQmx_ResetDevice("dev1")
Dowindow /k Oscilloscope
end

///////////////////////////////////////////////
Function OscTimeWindow(ctrlName,varNum,varStr,varName) : SetVariableControl
String ctrlName
Variable varNum
String varStr
String varName

setdatafolder root:cLTP
Variable/G  Timewindow,fmuestreo,C1i,C2i, C3i,C4i

 fDAQmx_WaveformStop("dev1")
 fDAQmx_ScanStop("dev1")
 fDAQmx_ResetDevice("dev1")
  
	 Make /O /N=((Timewindow/1000)*fmuestreo) Channel1Osc
	 SetScale/P x, 0,(1/fmuestreo), "s", Channel1Osc
	Make /O /N=((Timewindow/1000)*fmuestreo) Channel2Osc
	 SetScale/P x, 0,(1/fmuestreo), "s", Channel2Osc
	Make /O /N=((Timewindow/1000)*fmuestreo) Channel3Osc 
	 SetScale/P x, 0,(1/fmuestreo), "s", Channel3Osc
	Make /O /N=((Timewindow/1000)*fmuestreo) Channel4Osc
	 SetScale/P x, 0,(1/fmuestreo), "s", Channel4Osc

 String OscList="Channel1Osc, "+num2str(C1i)+";"+"Channel2Osc, "+num2str(C2i)+";"+"Channel3Osc, "+num2str(C3i)+";"+"Channel4Osc, "+num2str(C4i)+";"

	DAQmx_Scan /DEV="dev1" /BKG /RPT 	WAVES=OscList
	setdatafolder root:
	
end
//////////////////////////////////////////////////////////////////////////////////////

function Gvariablechanged (ctrlName,varNum,varStr,varName) : SetVariableControl
	
	String ctrlName
	Variable varNum	// value of variable as number
	String varStr		// value of variable as string
	String varName	// name of variable
	
	setdatafolder root:cLTP:
	Variable /G C1,C2,C3,C4
	
	Pulseinit ("Ctrl",0," "," ")
	if (C1==1)
	 WaveInit ("C1",1) 
	endif
	if (C2==1)
	 WaveInit ("C2",1) 
	endif
	if (C3==1)
	 WaveInit ("C3",1) 
	endif
	if (C4==1)
	 WaveInit ("C4",1) 
	endif
	
	end
	
	
	/////////////////////////////////////////////////////////////////////////////
	function activatebuttons()
	
	Button RunProtocolG, win=LTP,disable=0
	Button RunProtocol1,  win=LTP,disable=0
	Button RunProtocol2, win=LTP,disable=0
	Button RunProtocol3, win=LTP,disable=0
	Button RunProtocol4,  win=LTP,disable=0
	Button test1, win=LTP,disable=0
	Button test2, win=LTP,disable=0
	Button test3, win=LTP,disable=0
	Button test4, win=LTP,disable=0
	end
	
	///////////////////////////////////////
	function Savetodisk(Channel)
	string Channel
	string Path2
	setdatafolder root:cLTP
	variable /G L,recordtime,lastsave
	string /G namefile
	pathinfo path1
 		Path2=s_path+namefile+":"+Channel
		Newpath/q /O/C pathG, (s_path+namefile)
 		 Newpath /q/O/C pathS, Path2
		
	If ((mod(L,recordTime))==0 && L>=recordTime )
		Newpath /Q/O/C/Z pathavg,  (Path2+":Averaged_Sweeps")
		Newpath /Q/O/C/Z pathraw,  (Path2+":Raw_Sweeps")
		
		setdatafolder root:cLTP:Averaged_Sweeps:$(namefile):$(Channel)
		SAVEDATA /q/o  /D=1/p=pathavg /j=(Channel+"_"+num2str(L-1))    ":"
		setdatafolder root:cLTP:Raw_Sweeps:$(namefile):$(Channel)
		string Tosavelist=""
		variable i=0
		Do
		Tosavelist=Tosavelist+(Channel+"_"+num2str(L-recordTime+i))+";"
		i=i+1
		while (i<recordTime)
	SAVEDATA  /o/q /D=1/p=pathraw /j=Tosavelist   (Path2+":Raw_Sweeps")
	endif
	end
	
	
	
	
	
	
	
	
	////////////////////////////////////////////////////////////////////////
	Function CDisplay(Buttname) : ButtonControl
	
	string Buttname
	
String Ctrlname=Buttname[0,1]

variable checked

Setdatafolder Root:cLTP:

string /G CCoord,ColorList
variable /g Sweeplength,fmuestreo,dur,n,ppcheck, C1i,C2i, C3i,C4i
string /G TheWaveList,namefile
string Kwindow 

string color=(StringByKey(("C"+(Ctrlname[1])), ColorList  , "=", ";") )
variable top=str2num(StringByKey(("C"+(Ctrlname[1])+"T"), CCoord  , "=", ";") )
variable bottom=str2num(StringByKey(("C"+(Ctrlname[1])+"B"), CCoord  , "=", ";") )
variable ctrlnamenumber=str2num(Ctrlname[1])
	
	if (cmpstr(Buttname[2],"A")==0)
			Dowindow $(Ctrlname+"_Avg")
				if (v_flag==1)
				Dowindow /K $(Ctrlname+"_Avg")
				setdatafolder root:
				return 0
				else
				wave Awave=root:cLtp:$(Ctrlname+"wave_Avg")
				Display/K=2 /M/W=(8.2,(top),16,(bottom)) /N=$(Ctrlname+"_Avg") Awave
				modifygraph lblLatPos(left)=50,margin(bottom)=23,margin(top)=3,margin(right)=3,margin(left)=23,tick=1, lblMargin=5,ZisZ=1,zapTZ=1,zapLZ=1,lsize=1.5 , fsize=8, rgb=((str2num(stringfromlist(0,color,","))),(str2num(stringfromlist(1,color,","))),(str2num(stringfromlist(2,color,",")))) 
				Label left "mV" 
				Label bottom "\\u#2"			
				endif
	endif
	
	if (cmpstr(Buttname[2],"d")==0)

		Dowindow $(Ctrlname+num2str(0))
		if (v_flag==1)
		Dowindow /K $(Ctrlname+num2str(0))
		setdatafolder root:
		return 0
		else
		wave wav=root:cLTP:$(Ctrlname+"wave")

		Display/K=2 /M/W=(0,(top),8,(bottom)) /N=$(Ctrlname) wav
		modifygraph  lblLatPos(left)=50,margin(top)=3,margin(right)=3,margin(bottom)=23,margin(left)=23,tick=1,lblMargin=5,ZisZ=1,zapTZ=1,zapLZ=1,lsize=1.5 , fsize=8,  rgb=((str2num(stringfromlist(0,color,","))),(str2num(stringfromlist(1,color,","))),(str2num(stringfromlist(2,color,",")))) 
		Cursor /H=0/p	/C=(0,65280,0)  A $(Ctrlname+"wave") (.1*(numpnts(wav)))
		Cursor  /H=0/p	/C=(0,65280,0)  B $(Ctrlname+"wave")  (.2*(numpnts(wav)))
		Cursor  /H=2/p	/C=(65280,16384,16384) C $(Ctrlname+"wave")  (.3*(numpnts(wav)))
		Cursor  /H=2/p	/C=(65280,16384,16384) D $(Ctrlname+"wave")  (.5*(numpnts(wav)))
		Cursor  /H=2/p	/C=(52224,0,0) E $(Ctrlname+"wave")  (.7*(numpnts(wav)))
		Label left "mV"
		Label bottom "\\u#2"
	endif
		endif
		
setdatafolder root:
end

