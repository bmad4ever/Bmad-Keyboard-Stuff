#Include Midi Functions.ahk
  
; Open the Windows midi API dll
  hModule := OpenMidiAPI()

; Open the midi port
  h_midiout := midiOutOpen(1)

;------------------------------------------------------------------------------

; the lowest possible note
lbn := 48

; keysets (must play 2 sets simultaneously to output a note)
; keys ordered by ascending pitch
KeySet1 := ["z","x","c","v","b",   "a","s","d","f","g",   "q","w","e","r","t",   "1","2","3","4","5"]
KeySet2 := ["n","m",",",".","/",   "h","j","k","l",";",   "y","u","i","o","p",   "6","7","8","9","0"]

; create list of available notes states
; 2nd index stores the current state of the note on the loop
; 1st index stores the state of the note on the previous loop iteration
NoteSet := {}
ii := 1
Loop,  40
{
    NoteSet[ii] := [false, false]
    ii := ii+1
}

;------------------------------------------------------------------------------
Loop{
    bns1 := []
    bns2 := []
    
    for index, key in KeySet1 
            if( GetKeyState(key, "P") )
                bns1.push(index)
                
    for index, key in KeySet2 
            if( GetKeyState(key, "P") )
                bns2.push(index)
                
    for i1, v1 in bns1
        for i2, v2 in bns2  
            NoteSet[v1+v2-1][2] := true
            
    for index, states in NoteSet
    {
        if states[1] != states[2] 
        {
        
            if states[2] 
                midiOutShortMsg(h_midiout, "N1", 1, lbn + index - 1, 100)
            else
                midiOutShortMsg(h_midiout, "N0", 1, lbn + index - 1, 100)
        }
        
        ;setup values for next loop iteration
        NoteSet[index][1] := NoteSet[index][2]
        NoteSet[index][2] := false
    }
    
    sleep, 10
}