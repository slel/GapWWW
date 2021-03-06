years:=[1987..2018];

bib := ParseBibFiles("gap-publishednicer.bib")[1];;
Print( "Loaded ", Length(bib), " records\n");
# no need to sort the records - in this bib-file they are already sorted 

# tweaking some records on which ParseBibXMLextString chokes
for x in bib do
  if IsBound( x.Label ) then
    if x.Label="MR2831404" then
      Print(x.Label, " : fixing ", x.author, "\n");
      x.author := "de Klerk, E. and Dobre, C. and Pasechnik, D. V.";
    fi;
    if x.Label in ["MR1239007","MR2014017", "MR2014018", "MR2032853", "MR1993163"] then
      Print(x.Label, " : fixing inproceedings volume ", x.volume, " and number ", x.number, "\n");
      x.Volume:=Concatenation(x.volume, "(", x.number, ")" );
      Unbind(x.number);
    fi;    
    if x.Label = "MR2987109" then
      Print(x.Label, " : unbinding ISSN number\n");
      Unbind(x.issn);
    fi;    
  fi;
od;

sortedbyyears:=rec();
for y in years do
  sortedbyyears.(y):=[];
od;
sortedbyyears.noyear:=[];

for x in bib do
  if IsBound( x.year ) then
    if Int(x.year) in years then
      Add( sortedbyyears.(Int(x.year)), x );
    elif Length(x.year)=7 and x.year[5]='/' then 
      # year in format "2001/02"
      newyear := x.year{[1,2,6,7]};
      Print(x.Label, " : Year ", x.year, " --> ", newyear, "\n");
      Add( sortedbyyears.(Int(newyear)), x );
    else
      Print("WARNING: Unrecognised year in ", x, "\n");
      Add( sortedbyyears.noyear, x );
    fi;
  else
    Print("WARNING: No year given in ", x.Label, "\n");
    Add( sortedbyyears.noyear, x );
  fi;
od;  

for y in Concatenation(years,["noyear"]) do
  bib2 := sortedbyyears.(y);
  filename:=Filename( Directory("Year"), Concatenation( String(y), ".mixer") );
  output := OutputTextFile( filename, false );;
  SetPrintFormattingStatus( output, false );
  AppendTo( output,"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n");
  AppendTo( output,"<mixer template=\"gw.tmpl\">\n");
  AppendTo( output,"<mixertitle>", Length(bib2), 
                   " publications using <mixer var=\"GAP\"/> published in ", y, "</mixertitle>\n");
  for b in bib2 do 
    AppendTo(output, StringBibAsHTML(b), "\n"); 
  od; 
  AppendTo(output,"</mixer>\n");
od;

Read("MSC2010.g");
msccodes:=List(MSC2010, w -> w[1]);
mscnames:=List(MSC2010, w -> w[2]);
SortParallel( msccodes, mscnames);
posnomsc := Position( msccodes, "XX" );

sortedbymsc:=rec();
for code in msccodes do
  sortedbymsc.(code):=[];
od;

for b in bib do
  if IsBound(b.mrclass) then
    nr := b.mrclass;
    prim := nr{[1..2]};
    pos := Position( msccodes, prim ); 
    if pos <> fail then
      Add( sortedbymsc.( msccodes[pos] ), b );
      pos := PositionSublist( nr, " (" );
      if pos <> fail then
        sec := SplitString( nr{[pos+2..Length(nr)]}, " ", " )");
        sec := Set( List( sec, q -> q{[1..2]} ) );
        for q in sec do 
          if q <> prim then
            pos := Position( msccodes, q ); 
            Add( sortedbymsc.( msccodes[pos] ), b );
          fi;
        od;
      fi;  
    else  
      Add( sortedbymsc.( "XX" ), b );
    fi;
  else
    Add( sortedbymsc.( "XX" ), b );
  fi;  
od;

for y in msccodes do
  if Length( sortedbymsc.(y) ) > 0 then
  bib2 := sortedbymsc.(y);
  filename:=Filename( Directory("MSC"), Concatenation( String(y), ".mixer" ) );
  output := OutputTextFile( filename, false );;
  SetPrintFormattingStatus( output, false );
  AppendTo( output,"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n");
  AppendTo( output,"<mixer template=\"gw.tmpl\">\n");
  AppendTo( output,"<mixertitle>", Length(bib2), 
                   " publications using <mixer var=\"GAP\"/> in the category \"",
                   mscnames[Position(msccodes,y)], "\"</mixertitle>\n");
  for b in bib2 do 
    AppendTo(output, StringBibAsHTML(b), "\n"); 
  od; 
  AppendTo(output,"</mixer>\n");
  CloseStream(output);
  fi;
od;


