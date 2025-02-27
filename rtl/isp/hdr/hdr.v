module HDR
(
   	input		[23:0]	Pre_YUV,
   	input				Pre_YUV_en,
   	output		[23:0]	Post_YUV,
   	output				Post_YUV_en
);

reg	[7:0]	Post_Data;
assign Post_YUV = {Post_Data,Pre_YUV[15:0]};
assign Post_YUV_en = Pre_YUV_en;
always@(*)
begin
	case(Pre_YUV[23:16])
	8'h00 : Post_Data = 8'h11; 
	8'h01 : Post_Data = 8'h1B; 
	8'h02 : Post_Data = 8'h23; 
	8'h03 : Post_Data = 8'h28; 
	8'h04 : Post_Data = 8'h2D; 
	8'h05 : Post_Data = 8'h31; 
	8'h06 : Post_Data = 8'h34; 
	8'h07 : Post_Data = 8'h37; 
	8'h08 : Post_Data = 8'h3A; 
	8'h09 : Post_Data = 8'h3C; 
	8'h0A : Post_Data = 8'h3E; 
	8'h0B : Post_Data = 8'h40; 
	8'h0C : Post_Data = 8'h42; 
	8'h0D : Post_Data = 8'h44; 
	8'h0E : Post_Data = 8'h45; 
	8'h0F : Post_Data = 8'h47; 
	8'h10 : Post_Data = 8'h48; 
	8'h11 : Post_Data = 8'h4A; 
	8'h12 : Post_Data = 8'h4B; 
	8'h13 : Post_Data = 8'h4C; 
	8'h14 : Post_Data = 8'h4D; 
	8'h15 : Post_Data = 8'h4E; 
	8'h16 : Post_Data = 8'h4F; 
	8'h17 : Post_Data = 8'h50; 
	8'h18 : Post_Data = 8'h51; 
	8'h19 : Post_Data = 8'h52; 
	8'h1A : Post_Data = 8'h53; 
	8'h1B : Post_Data = 8'h54; 
	8'h1C : Post_Data = 8'h55; 
	8'h1D : Post_Data = 8'h56; 
	8'h1E : Post_Data = 8'h57; 
	8'h1F : Post_Data = 8'h57; 
	8'h20 : Post_Data = 8'h58; 
	8'h21 : Post_Data = 8'h59; 
	8'h22 : Post_Data = 8'h5A; 
	8'h23 : Post_Data = 8'h5A; 
	8'h24 : Post_Data = 8'h5B; 
	8'h25 : Post_Data = 8'h5C; 
	8'h26 : Post_Data = 8'h5C; 
	8'h27 : Post_Data = 8'h5D; 
	8'h28 : Post_Data = 8'h5D; 
	8'h29 : Post_Data = 8'h5E; 
	8'h2A : Post_Data = 8'h5F; 
	8'h2B : Post_Data = 8'h5F; 
	8'h2C : Post_Data = 8'h60; 
	8'h2D : Post_Data = 8'h60; 
	8'h2E : Post_Data = 8'h61; 
	8'h2F : Post_Data = 8'h61; 
	8'h30 : Post_Data = 8'h62; 
	8'h31 : Post_Data = 8'h62; 
	8'h32 : Post_Data = 8'h63; 
	8'h33 : Post_Data = 8'h63; 
	8'h34 : Post_Data = 8'h64; 
	8'h35 : Post_Data = 8'h64; 
	8'h36 : Post_Data = 8'h65; 
	8'h37 : Post_Data = 8'h65; 
	8'h38 : Post_Data = 8'h66; 
	8'h39 : Post_Data = 8'h67; 
	8'h3A : Post_Data = 8'h67; 
	8'h3B : Post_Data = 8'h68; 
	8'h3C : Post_Data = 8'h68; 
	8'h3D : Post_Data = 8'h69; 
	8'h3E : Post_Data = 8'h69; 
	8'h3F : Post_Data = 8'h6A; 
	8'h40 : Post_Data = 8'h6A; 
	8'h41 : Post_Data = 8'h6B; 
	8'h42 : Post_Data = 8'h6B; 
	8'h43 : Post_Data = 8'h6C; 
	8'h44 : Post_Data = 8'h6C; 
	8'h45 : Post_Data = 8'h6D; 
	8'h46 : Post_Data = 8'h6D; 
	8'h47 : Post_Data = 8'h6E; 
	8'h48 : Post_Data = 8'h6E; 
	8'h49 : Post_Data = 8'h6F; 
	8'h4A : Post_Data = 8'h6F; 
	8'h4B : Post_Data = 8'h70; 
	8'h4C : Post_Data = 8'h70; 
	8'h4D : Post_Data = 8'h71; 
	8'h4E : Post_Data = 8'h71; 
	8'h4F : Post_Data = 8'h72; 
	8'h50 : Post_Data = 8'h72; 
	8'h51 : Post_Data = 8'h73; 
	8'h52 : Post_Data = 8'h74; 
	8'h53 : Post_Data = 8'h74; 
	8'h54 : Post_Data = 8'h75; 
	8'h55 : Post_Data = 8'h75; 
	8'h56 : Post_Data = 8'h76; 
	8'h57 : Post_Data = 8'h76; 
	8'h58 : Post_Data = 8'h77; 
	8'h59 : Post_Data = 8'h77; 
	8'h5A : Post_Data = 8'h78; 
	8'h5B : Post_Data = 8'h78; 
	8'h5C : Post_Data = 8'h79; 
	8'h5D : Post_Data = 8'h79; 
	8'h5E : Post_Data = 8'h7A; 
	8'h5F : Post_Data = 8'h7A; 
	8'h60 : Post_Data = 8'h7B; 
	8'h61 : Post_Data = 8'h7B; 
	8'h62 : Post_Data = 8'h7C; 
	8'h63 : Post_Data = 8'h7C; 
	8'h64 : Post_Data = 8'h7D; 
	8'h65 : Post_Data = 8'h7D; 
	8'h66 : Post_Data = 8'h7E; 
	8'h67 : Post_Data = 8'h7E; 
	8'h68 : Post_Data = 8'h7F; 
	8'h69 : Post_Data = 8'h7F; 
	8'h6A : Post_Data = 8'h80; 
	8'h6B : Post_Data = 8'h81; 
	8'h6C : Post_Data = 8'h81; 
	8'h6D : Post_Data = 8'h82; 
	8'h6E : Post_Data = 8'h82; 
	8'h6F : Post_Data = 8'h83; 
	8'h70 : Post_Data = 8'h83; 
	8'h71 : Post_Data = 8'h84; 
	8'h72 : Post_Data = 8'h84; 
	8'h73 : Post_Data = 8'h85; 
	8'h74 : Post_Data = 8'h85; 
	8'h75 : Post_Data = 8'h86; 
	8'h76 : Post_Data = 8'h86; 
	8'h77 : Post_Data = 8'h87; 
	8'h78 : Post_Data = 8'h87; 
	8'h79 : Post_Data = 8'h88; 
	8'h7A : Post_Data = 8'h88; 
	8'h7B : Post_Data = 8'h89; 
	8'h7C : Post_Data = 8'h89; 
	8'h7D : Post_Data = 8'h8A; 
	8'h7E : Post_Data = 8'h8A; 
	8'h7F : Post_Data = 8'h8B; 
	8'h80 : Post_Data = 8'h8B; 
	8'h81 : Post_Data = 8'h8C; 
	8'h82 : Post_Data = 8'h8C; 
	8'h83 : Post_Data = 8'h8D; 
	8'h84 : Post_Data = 8'h8E; 
	8'h85 : Post_Data = 8'h8E; 
	8'h86 : Post_Data = 8'h8F; 
	8'h87 : Post_Data = 8'h8F; 
	8'h88 : Post_Data = 8'h90; 
	8'h89 : Post_Data = 8'h90; 
	8'h8A : Post_Data = 8'h91; 
	8'h8B : Post_Data = 8'h91; 
	8'h8C : Post_Data = 8'h92; 
	8'h8D : Post_Data = 8'h92; 
	8'h8E : Post_Data = 8'h93; 
	8'h8F : Post_Data = 8'h93; 
	8'h90 : Post_Data = 8'h94; 
	8'h91 : Post_Data = 8'h94; 
	8'h92 : Post_Data = 8'h95; 
	8'h93 : Post_Data = 8'h95; 
	8'h94 : Post_Data = 8'h96; 
	8'h95 : Post_Data = 8'h96; 
	8'h96 : Post_Data = 8'h97; 
	8'h97 : Post_Data = 8'h97; 
	8'h98 : Post_Data = 8'h98; 
	8'h99 : Post_Data = 8'h98; 
	8'h9A : Post_Data = 8'h99; 
	8'h9B : Post_Data = 8'h99; 
	8'h9C : Post_Data = 8'h9A; 
	8'h9D : Post_Data = 8'h9B; 
	8'h9E : Post_Data = 8'h9B; 
	8'h9F : Post_Data = 8'h9C; 
	8'hA0 : Post_Data = 8'h9C; 
	8'hA1 : Post_Data = 8'h9D; 
	8'hA2 : Post_Data = 8'h9D; 
	8'hA3 : Post_Data = 8'h9E; 
	8'hA4 : Post_Data = 8'h9E; 
	8'hA5 : Post_Data = 8'h9F; 
	8'hA6 : Post_Data = 8'h9F; 
	8'hA7 : Post_Data = 8'hA0; 
	8'hA8 : Post_Data = 8'hA0; 
	8'hA9 : Post_Data = 8'hA1; 
	8'hAA : Post_Data = 8'hA1; 
	8'hAB : Post_Data = 8'hA2; 
	8'hAC : Post_Data = 8'hA2; 
	8'hAD : Post_Data = 8'hA3; 
	8'hAE : Post_Data = 8'hA3; 
	8'hAF : Post_Data = 8'hA4; 
	8'hB0 : Post_Data = 8'hA4; 
	8'hB1 : Post_Data = 8'hA5; 
	8'hB2 : Post_Data = 8'hA5; 
	8'hB3 : Post_Data = 8'hA6; 
	8'hB4 : Post_Data = 8'hA6; 
	8'hB5 : Post_Data = 8'hA7; 
	8'hB6 : Post_Data = 8'hA8; 
	8'hB7 : Post_Data = 8'hA8; 
	8'hB8 : Post_Data = 8'hA9; 
	8'hB9 : Post_Data = 8'hA9; 
	8'hBA : Post_Data = 8'hAA; 
	8'hBB : Post_Data = 8'hAA; 
	8'hBC : Post_Data = 8'hAB; 
	8'hBD : Post_Data = 8'hAB; 
	8'hBE : Post_Data = 8'hAC; 
	8'hBF : Post_Data = 8'hAC; 
	8'hC0 : Post_Data = 8'hAD; 
	8'hC1 : Post_Data = 8'hAD; 
	8'hC2 : Post_Data = 8'hAE; 
	8'hC3 : Post_Data = 8'hAE; 
	8'hC4 : Post_Data = 8'hAF; 
	8'hC5 : Post_Data = 8'hAF; 
	8'hC6 : Post_Data = 8'hB0; 
	8'hC7 : Post_Data = 8'hB0; 
	8'hC8 : Post_Data = 8'hB1; 
	8'hC9 : Post_Data = 8'hB1; 
	8'hCA : Post_Data = 8'hB2; 
	8'hCB : Post_Data = 8'hB2; 
	8'hCC : Post_Data = 8'hB3; 
	8'hCD : Post_Data = 8'hB3; 
	8'hCE : Post_Data = 8'hB4; 
	8'hCF : Post_Data = 8'hB5; 
	8'hD0 : Post_Data = 8'hB5; 
	8'hD1 : Post_Data = 8'hB6; 
	8'hD2 : Post_Data = 8'hB6; 
	8'hD3 : Post_Data = 8'hB7; 
	8'hD4 : Post_Data = 8'hB7; 
	8'hD5 : Post_Data = 8'hB8; 
	8'hD6 : Post_Data = 8'hB8; 
	8'hD7 : Post_Data = 8'hB9; 
	8'hD8 : Post_Data = 8'hB9; 
	8'hD9 : Post_Data = 8'hBA; 
	8'hDA : Post_Data = 8'hBB; 
	8'hDB : Post_Data = 8'hBB; 
	8'hDC : Post_Data = 8'hBC; 
	8'hDD : Post_Data = 8'hBD; 
	8'hDE : Post_Data = 8'hBE; 
	8'hDF : Post_Data = 8'hBF; 
	8'hE0 : Post_Data = 8'hC0; 
	8'hE1 : Post_Data = 8'hC1; 
	8'hE2 : Post_Data = 8'hC2; 
	8'hE3 : Post_Data = 8'hC3; 
	8'hE4 : Post_Data = 8'hC5; 
	8'hE5 : Post_Data = 8'hC6; 
	8'hE6 : Post_Data = 8'hC7; 
	8'hE7 : Post_Data = 8'hC8; 
	8'hE8 : Post_Data = 8'hCA; 
	8'hE9 : Post_Data = 8'hCB; 
	8'hEA : Post_Data = 8'hCD; 
	8'hEB : Post_Data = 8'hCF; 
	8'hEC : Post_Data = 8'hD0; 
	8'hED : Post_Data = 8'hD2; 
	8'hEE : Post_Data = 8'hD4; 
	8'hEF : Post_Data = 8'hD5; 
	8'hF0 : Post_Data = 8'hD7; 
	8'hF1 : Post_Data = 8'hD9; 
	8'hF2 : Post_Data = 8'hDB; 
	8'hF3 : Post_Data = 8'hDD; 
	8'hF4 : Post_Data = 8'hDF; 
	8'hF5 : Post_Data = 8'hE1; 
	8'hF6 : Post_Data = 8'hE3; 
	8'hF7 : Post_Data = 8'hE6; 
	8'hF8 : Post_Data = 8'hE8; 
	8'hF9 : Post_Data = 8'hEA; 
	8'hFA : Post_Data = 8'hED; 
	8'hFB : Post_Data = 8'hEF; 
	8'hFC : Post_Data = 8'hF1; 
	8'hFD : Post_Data = 8'hF4; 
	8'hFE : Post_Data = 8'hF7; 
	8'hFF : Post_Data = 8'hF9; 
	endcase
end

endmodule