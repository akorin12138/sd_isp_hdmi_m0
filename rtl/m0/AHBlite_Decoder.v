module AHBlite_Decoder
#(
    /*RAMCODE enable parameter*/
    parameter Port0_en = 1,
    /************************/

    /*WaterLight enable parameter*/
    parameter Port1_en = 1,
    /************************/

    /*RAMDATA enable parameter*/
    parameter Port2_en = 1,
    /************************/

    /*UART enable parameter*/
    parameter Port3_en = 1,
    /************************/

    /*GPIO enable parameter*/
    parameter Port4_en = 1,

    /*SDcard enable parameter*/
    parameter Port5_en = 1,
    /************************/

    /*SDcard enable parameter*/
    parameter Port6_en = 1
    /************************/
)(
    input [31:0] HADDR,

    /*RAMCODE OUTPUT SELECTION SIGNAL*/
    output wire P0_HSEL,

    /*WaterLight OUTPUT SELECTION SIGNAL*/
    output wire P1_HSEL,

    /*RAMDATA OUTPUT SELECTION SIGNAL*/
    output wire P2_HSEL,

    /*UART OUTPUT SELECTION SIGNAL*/
    output wire P3_HSEL,

    /*GPIO OUTPUT SELECTION SIGNAL*/
    output wire P4_HSEL,

    /*SDcard OUTPUT SELECTION SIGNAL*/
    output wire P5_HSEL,

    /*ISP OUTPUT SELECTION SIGNAL*/
    output wire P6_HSEL
);

//RAMCODE-----------------------------------

//0x00000000-0x0000ffff
/*Insert RAMCODE decoder code there*/
assign P0_HSEL = (HADDR[31:16] == 16'h0000) ? Port0_en : 1'b0; 
/***********************************/

//RAMDATA-----------------------------

//0X20000000-0X2000FFFF
/*Insert RAMDATA decoder code there*/
assign P1_HSEL = (HADDR[31:16] == 16'h2000) ? Port1_en : 1'b0;
/***********************************/

//PERIPHRAL-----------------------------

//0X40000000 WaterLight MODE
//0x40000004 WaterLight SPEED
/*Insert WaterLight decoder code there*/
assign P2_HSEL = (HADDR[31:16] == 16'h4000) ? Port2_en : 1'b0;
/***********************************/

//0X40000010 UART RX DATA
//0X40000014 UART TX STATE
//0X40000018 UART TX DATA
/*Insert UART decoder code there*/
assign P3_HSEL = (HADDR[31:16] == 16'h4001) ? Port3_en : 1'b0;
/***********************************/

//0x40000028 OUT  ENABLE
//0X40000024 IN DATA
//0X40000020 OUT DATA
/*Insert GPIO decoder code there*/
assign P4_HSEL = (HADDR[31:16] == 28'h4002) ? Port4_en : 1'd0;
/***********************************/

//0x4000003c reserve
//0x40000038 reserve
//0X40000034 reserve
//0X40000030 reserve
/*Insert SDcard decoder code there*/
assign P5_HSEL = (HADDR[31:16] == 16'h4003) ? Port5_en : 1'd0;
/***********************************/

//0x4000004c reserve
//0x40000048 reserve
//0X40000044 reserve
//0X40000040 reserve
/*Insert ISP decoder code there*/
assign P6_HSEL = (HADDR[31:16] == 16'h4004) ? Port6_en : 1'd0;
/***********************************/

endmodule