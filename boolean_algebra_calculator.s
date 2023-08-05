; GPIO base addresses of port D,E,F and H
gpioDbase	EQU		0x4005B000 ; gate
gpioHbase	EQU		0x4005F000 ; output
gpioEbase	EQU		0x4005C000 ; binary input1
gpioFbase	EQU		0x4005D000 ; binary input2
	
	
; GPIO offsets, least significant 8 bits (mostly)
gpioData	EQU		0x000	; 'data' add relevant gpio data mask offset for masking, to read or write all values add 0x3FC to base which is sum of all bit constants
gpioDir		EQU		0x400	; 'direction' 0 for inp, 1 for out, inp by default
gpioAfsel	EQU		0x420	; 'alterrnate function select' 0 for standard gpio and gpio register used in this time, 1 for path over selected alternate hardware function, hardware function selection is done by gpiopctl register control, 0 default
gpioPctrl	EQU		0x52C	; 'port control' see documentation
gpioLock	EQU		0x520	; to unlock 0x4c4f434b shoulb be written, any other write locks back, enables write access to gpiocr
gpioCr		EQU		0x524	; 'commit' gpioafsel, pur, pdr, den can only be changed with setting bit in cr, only modified when unlock gpiolock
gpioAmsel	EQU		0x528	; 'analog mode select' only valid for pins of adc, set for analog, 
gpioDen		EQU		0x51c	; 'digital enable' 

; GPIO data mask offset constant, [9:2] in address are ussed for [7:0] bits masking 
; to only write to pin 5 of any port 'five' offset should be added to gpiodata
; to only write to pins 2 and 5 of any port data should be written dataregister address + 'two'+'five' offset address remainings left unchange in output 0 in input mode
gpioDataZero	EQU		0x004
gpioDataOne		EQU		0x008
gpioDataTwo		EQU		0x010
gpioDataThree	EQU		0x020
gpioDataFour	EQU		0x040
gpioDataFive	EQU		0x080
gpioDataSix		EQU		0x100
gpioDataSeven	EQU		0x200

; GPIO Interrupt registers, least significant 8 bits (mostly)
gpioIs		EQU		0x404	; 'interrupt sense' 1 for level sensitivity, 0 for edge sensitivity
gpioIbe		EQU		0x408	; 'interrupt both edges' if 1 regardless of gpioie register interrupt occur for both edge, if 0 gpioie register define which edge, default 0 all
gpioIev		EQU		0x40C	; 'interrupt evet' 1 for rising edge, 0 for falling edge, 0 default
gpioIm		EQU		0x410	; 'interrupt mask' 1 to sendt interrupt co interrupt controller, 0 default
gpioRis		EQU		0x414	; 'raw interrupt status' read only, set automatically if interrupt occur if gpioim is set interrupt sent is to interrupt controller, if level detectin signal must be held until serviced, if edge write 1 to gpioicr to erase relavent gpioris, gpiomis is the masked value of gpioris
gpioMis		EQU		0x418	; 'masked interrupt status' readonly, if 1 sent to interrupt controller, if 0 no interrupt or masked
gpioIcr		EQU		0x41C	; 'interrupt clear' for edge sensitivity write 1 clears gpiomis and gpioris, no effect on level detect, no effect writing 0
	
; GPIO Pad control registers
gpioDr2r	EQU		0x500	; '2ma drive select' if select dr4r, dr8r cleared automatically, all set default
gpioDr4r	EQU		0x504
gpioDr8r	EQU		0x508	; used for high current applications
gpioOdr		EQU		0x50C	; 'open drain select' set for open drain, if set corresponding gpioden bit should also be set, gpiodr2r, 4r,8r, gpioslr should be used for desired fall time, if pin is imput no effect 
gpioPur		EQU		0x510	; 'pullup select' set to add 20k ohm pullup, if set gpiopdr automatically cleared, write access protected by gpiocr register
gpioPdr		EQU		0x514	; 'pulldownselect' 
gpioSlr		EQU		0x518	; 'slew rate sontrol select' available only when 8ma strength used

; GPIO clck gating register 
; default 0 and disabled by clck blocking
; bit #0 for port A and #1 for port B should be set to enable ports
; after setting 3 clck cycle is needed to reach port registers properly
rcgcgpio	EQU		0x400FE608	
delayAmount EQU		0x0BCA00
dataSaveAdrr EQU    0x20000200
;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;

    area mycode, code
	align
	entry
		
	export		__main

__main
;;;;;;;;;;;;;;;;;
		NOP
		BL initializegpio						; porte is adjusted as output and portd as input use porte bit 0 and 1 and portd bit 0 for this experiment for the following code blocks
	
gateSwitch		
                LDR R1, =gpioDbase
	            ADD R1, #0x3C                  ;(0x004) + (0x008) + (0x010) + (0x020) = 0x3C  masking
	            LDR R0, [R1]                    ; 4 LSB are used to read input to choose logic operators
	
	
				CMP R0,#0x1                    ;0001   Reading the first bit
				BEQ and_gate					
				
				CMP R0,#0x2                    ;0010	Reading the second bit
				BEQ orr_gate
				
				CMP R0,#0x4                    ;0100	Reading the third bit
				BEQ eor_gate
				
				CMP R0,#0x8                    ;1000	Reading the fourth bit
				BEQ bic_gate
				
				BNE gateSwitch
	     		;;;;;;;;
                
binary_sayilar
                LDR R1, =gpioEbase				; Port E is used to read the operand values
				LDR R2, =gpioFbase              ; Port F is used to read the operand values
				LDR R6,=dataSaveAdrr
				
	            ADD R1, #0x0C                   ; E port's zero and first pin for masking
				ADD R2, #0x0C                  ; F port's zero and first pin for masking
				
	            LDR R3, [R1]
				LDR R4, [R2]
				BX LR
				
				
and_gate		
				BL binary_sayilar
				
			    AND R5, R3, R4	  ; Logic AND operation
				STR R5, [R6]
				
				B output
				
				;;;;;;;;;;;;;;;;;
				
orr_gate		
				BL binary_sayilar
				
			    ORR R5, R3, R4	  ; Logic OR operation
				STR R5, [R6]
				
				B output
				;;;;;;;;;;;;;;;;;
				
eor_gate	    
				BL binary_sayilar
				
			    EOR R5, R3, R4   ; Logic Exclusive OR operation
				STR R5, [R6]
				
				B output
				;;;;;;;;;;;;;;;;;
				
bic_gate		  
                BL binary_sayilar
				
			    BIC R5, R3, R4   ; Logic Bit Clear operation
				STR R5, [R6]
				
				B output
				;;;;;;;;;;;;;;;;;
				
output
                LDR R1, =gpioHbase
				ADD R1, #0x0C                   ; H port's zero and first pin for masking
				LDR R0,[R6]
				STR R0,[R1]
				
delay
                LDR R8,=delayAmount              ; Delay amount defined above the main code
				B wait
wait   
				
				CMP R8,#0                       
				SUB R8,R8,#1
				BNE wait
				B gateSwitch                   ;End of the loop
				;;;;;;;;;;;;;;;;;
				
				


initializegpio
				; enable clck for ports D, E,F and H
				LDR R1, =rcgcgpio
				LDR R0, [R1]
				ORR R0, R0, #0xB8
				STR R0, [R1]
				NOP
				NOP
				NOP
				; out port H
				LDR R1, =gpioHbase
				ADD R1, R1, #gpioDir
				LDR R0, [R1]
				ORR R0, R0, #0x3F
				STR R0, [R1]
				
				; afsel
				LDR R1, =gpioEbase
				ADD R1, R1, #gpioAfsel
				LDR R0, [R1]
				BIC R0, #0xFF
				STR R0, [R1]
				LDR R1, =gpioHbase
				ADD R1, R1, #gpioAfsel
				LDR R0, [R1]
				BIC R0, #0xFF
				STR R0, [R1]
				LDR R1, =gpioDbase
				ADD R1, R1, #gpioAfsel
				LDR R0, [R1]
				BIC R0, #0xFF
				STR R0, [R1]
				LDR R1, =gpioFbase
				ADD R1, R1, #gpioAfsel
				LDR R0, [R1]
				BIC R0, #0xFF
				STR R0, [R1]
				
				; den 1 for ports
				LDR R1, =gpioHbase
				ADD R1, R1, #gpioDen
				LDR R0,[R1]
				ORR R0, R0, #0xFF
				STR R0, [R1]
				LDR R1, =gpioEbase
				ADD R1, R1, #gpioDen
				LDR R0,[R1]
				ORR R0, R0, #0xFF
				STR R0, [R1]
				LDR R1, =gpioDbase
				ADD R1, R1, #gpioDen
				LDR R0,[R1]
				ORR R0, R0, #0xFF
				STR R0, [R1]
				LDR R1, =gpioFbase
				ADD R1, R1, #gpioDen
				LDR R0,[R1]
				ORR R0, R0, #0xFF
				STR R0, [R1]
				
				BX LR

					
				ALIGN
                END