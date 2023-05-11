procedure( createMainForm()
let( (modeSel logSrc logDest confirmButton mainForm)
	/*
	tech = hiCreateCyclicField(?name 'tech
				   ?choices list("tsmcN65" "tsmcN40" "something else")
				   ?prompt "technology"
		)
	*/
	
	modeSel = hiCreateRadioField(	?name 'modeSel
					?choices '("log" "netlist" "sp")
					?prompt "input file type"
					?defValue "log"
					?callback '("modeChangeCallBack()")
		)
	
	logSrc = hiCreateStringField(	?name 'logSrc
					?prompt "log file path"
		)
	
	logDest = hiCreateStringField(	?name 'logDest
					?prompt "target path"
		)
		
	netSrc = hiCreateStringField(	?name 'netSrc
					?prompt "netlist file path"
					?enabled nil
		)
	
	netDest = hiCreateStringField(	?name 'netDest
					?prompt "target path"
					?enabled nil
		)
	
	confirmButton = hiCreateFormButton(	?name 'confirmButton
						?buttonText "Generate"
						?callback "generateCallBack()"
		)
	
	mainForm = hiCreateAppForm(?name 		'mainForm
				   ?formTitle 		"Layer&Comp Information Generator"
				   ?fields		list(modeSel logSrc logDest netSrc netDest confirmButton)
				   ?buttonLayout	'OKCancel
		)
	hiDisplayForm(mainForm)
);let
);procedure



procedure( generateCallBack()
   let( (dirList mode inDir outDir)
	mode = mainForm->modeSel->value
	case( mode
	    ("log"
	    /*
		printf("Start generate from log file\n")
		inDir = mainForm->logSrc->value
		outDir = mainForm->logDest->value
		printf("input path: %s\n" inDir)
		printf("output path: %s\n" outDir)
	 
	    
		
		;TODO invalid dir error		
		genLayerInfo(inDir outDir)
		printf("Generate success\n")
	    */
		printf("Start generate from log file(s)\n")
		inDir = mainForm->logSrc->value
		outDir = mainForm->logDest->value
		printf("output path: \"%s\"\n" outDir)
		genLayerInfoFromMultiSrcs(inDir outDir)
		printf("Generate successfully\n")
	    )
	    ("netlist"
	    /*
		printf("Start generate from netlist file(s)")
		inDir = mainForm->netSrc->value
		outDir = mainForm->netDest->value
		printf("input path: \"%s\"\n" inDir)
		printf("output path: \"%s\"\n" outDir)		
		;TODO invalid dir error		
		genCompList(inDir outDir)
		printf("Generate success\n")
	    */
		printf("Start generate from netlist file(s)")
		inDir = mainForm->netSrc->value
		outDir = mainForm->netDest->value
		printf("output path: \"%s\"\n" outDir)	
		genCompListFromMultiSrcs(inDir outDir)
		printf("Generate successfully\n")
	    )
	    );case
	);let
);procedure
    
procedure( genLayerInfoFromMultiSrcs(inDir outDir)
let( (fileRd fileWrt dir dirList layer_found layer_cnt line layerInfo layer layers)

    layer_found = -1
    layer_cnt = 0

    dirList = parseString(inDir ";")
    fileWrt = outfile(outDir)
    foreach(dir dirList
	
	 printf("start prcessing: \"%s\"\n" dir)
	 fileRd = infile(dir)
	 when(fileRd
	   /*
	   *  layer_found: -1 -- not found
	    *  		  0 -- found, but looking for data
	    *  		  1 -- ready to load data
	    *  		  2 -- data load finished	 
	    */
	    	while( gets(line fileRd) 

			when( layer_found == 0 layer_cnt++)
			when( (layer_cnt == 5) && (layer_found == 0) layer_found = 1);
			when( rexMatchp("Statistics of Layers" line)
				layer_found = 0
				layer_cnt = 0
			);endwhen			
			when( layer_found == 1 
				if( rexMatchp("-" line)
				then	layer_found = 2
				else
					layerInfo = parseString(line)
					if( nth(1,layerInfo) == "drawing"
						then sprintf(layer "%s,%s,%s" nth(0,layerInfo) nth(2,layerInfo) nth(3,layerInfo))
						else sprintf(layer "%s_%s,%s,%s" nth(0,layerInfo) nth(1,layerInfo) nth(2,layerInfo) nth(3,layerInfo))
					)
					when( member(layer layers) == nil layers = cons(layer layers))
					
					;if( nth(1,layerInfo) == "drawing"
					;    then	fprintf( fileWrt "%s,%s,%s\n" nth(0,layerInfo) nth(2,layerInfo) nth(3,layerInfo))
					;    else	fprintf( fileWrt "%s_%s,%s,%s\n" nth(0,layerInfo) nth(1,layerInfo) nth(2,layerInfo) nth(3,layerInfo))
					;)
						
				);if			
			);when	
	     
		);while	
	 printf("process \"%s\" finished\n" dir)
	);when
    );foreach
    	foreach( layer layers fprintf(fileWrt "%s\n" layer))
    	close(fileRd)
    	close(fileWrt)
);let
);procedure



procedure( genCompListFromMultiSrcs(inDir outDir)

let( (fileRd fileWrt dir dirList inst insts line word words)
    dirList = parseString(inDir ";")
    fileWrt = outfile(outDir)
    foreach(dir dirList
	
	    printf("start prcessing: \"%s\"\n" dir)
	    fileRd = infile(dir)
	    
	    when(fileRd		
		while( gets(line fileRd)
		    /* record components */
		    when( substring(line 1 1) != "+" && substring(line 1 1) != "*"

			when( rexMatchp("=" line) != nil
				words = parseString(line)
				words = reverse(words)
				inst = prog( ()
					    foreach(word words when(rexMatchp("=" word) == nil return(word)));foreach
					);prog					
				when( substring(inst 1 1) == "$" inst = substring(inst 3 strlen(inst)-3) )
				when( member(inst insts) == nil insts = cons(inst insts))					
			);when
		    );when
		);while
		
	    );when
	    printf("process \"%s\" finished\n" dir)
    );foreach
    foreach( inst insts fprintf(fileWrt "%s\n" inst))
    close(fileRd)
    close(fileWrt)
);let
);precedure

/*
procedure( genCompList(inDir outDir)
    
fileRd = infile(inDir)
fileWrt = outfile(outDir)

when(fileRd

	let( (inst insts line word words)
		
		while( gets(line fileRd)

			when( substring(line 1 1) != "+" && substring(line 1 1) != "*"

				when( rexMatchp("=" line) != nil
					;println(line)
					words = parseString(line)
					words = reverse(words)
					inst = prog( ()
							foreach(word words
								when(rexMatchp("=" word) == nil return(word))
							);foreach
						);prog
					
					when( substring(inst 1 1) == "$" inst = substring(inst 3 strlen(inst)-3) )
					when( member(inst insts) == nil insts = cons(inst insts))
					
				);when
			);when
		);while

		foreach( inst insts 
		    fprintf(fileWrt "%s\n" inst)
		)
	);let
);when

close(fileRd)
close(fileWrt)
)
*/

/*
procedure( genLayerInfo(inDir outDir)
    

fileRd = infile(inDir)


fileWrt = outfile(outDir)

when(file

let( (layer_found layer_cnt layerInfo)	
	layer_found = -1
	layer_cnt = 0

	while( gets(line fileRd) 

		if( layer_found == 0
			then	layer_cnt++;
			else		  
		);endif

		when( (layer_cnt == 5) && (layer_found == 0)
			layer_found = 1
		);endwhen

		when( rexMatchp("Statistics of Layers" line)
			layer_found = 0
			layer_cnt = 0
		);endwhen
			
		when( layer_found == 1 
			if( rexMatchp("-" line)
				then	layer_found = 2
				else
					layerInfo = parseString(line)
					if( nth(1,layerInfo) == "drawing"
					    then	fprintf( fileWrt "%s,%s,%s\n" nth(0,layerInfo) nth(2,layerInfo) nth(3,layerInfo))
					    else	fprintf( fileWrt "%s_%s,%s,%s\n" nth(0,layerInfo) nth(1,layerInfo) nth(2,layerInfo) nth(3,layerInfo))
					)
						
			)
				
		);when
			     
	);while		

	close(fileRd)
	close(fileWrt)
);let
);when
);procedure
*/

procedure( modeChangeCallBack()
    let( (mode)
	mode = modeSel->value
	case( mode
	    ( "log" 
		mainForm->logSrc->enabled = t
		mainForm->logDest->enabled = t
		mainForm->netSrc->enabled = nil
		mainForm->netDest->enabled = nil
		)
	    ( "netlist" 
		mainForm->logSrc->enabled = nil
		mainForm->logDest->enabled = nil
		mainForm->netSrc->enabled = t
		mainForm->netDest->enabled = t
		)
	    ( t	)
	);case
    );let
);procedure
