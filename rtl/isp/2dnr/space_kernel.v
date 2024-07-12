module space_Kernel #(
    parameter WEIGHT_BITS = 5,
    parameter BITS = 8
)(
    input pclk,
    input rst_n,

    output [7*7*WEIGHT_BITS-1:0] space_kernel, //空域卷积核(7x7)
    output [9*BITS-1:0]          color_curve_x,//值域卷积核拟合曲线横坐标(9个坐标点)
    output [9*WEIGHT_BITS-1:0]   color_curve_y //值域卷积核拟合曲线纵坐标(9个坐标点)
);

	reg [4:0] sw00, sw01, sw02, sw03, sw04, sw05, sw06;
	reg [4:0] sw10, sw11, sw12, sw13, sw14, sw15, sw16;
	reg [4:0] sw20, sw21, sw22, sw23, sw24, sw25, sw26;
	reg [4:0] sw30, sw31, sw32, sw33, sw34, sw35, sw36;
	reg [4:0] sw40, sw41, sw42, sw43, sw44, sw45, sw46;
	reg [4:0] sw50, sw51, sw52, sw53, sw54, sw55, sw56;
	reg [4:0] sw60, sw61, sw62, sw63, sw64, sw65, sw66;
	reg [BITS-1:0] cx0, cx1, cx2, cx3, cx4, cx5, cx6, cx7, cx8;
	reg [4:0]      cy0, cy1, cy2, cy3, cy4, cy5, cy6, cy7, cy8;
	always @(posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			sw00<=5'd28; sw01<=5'd29; sw02<=5'd29; sw03<=5'd30; sw04<=5'd29; sw05<=5'd29; sw06<=5'd28;
			sw10<=5'd29; sw11<=5'd30; sw12<=5'd30; sw13<=5'd30; sw14<=5'd30; sw15<=5'd30; sw16<=5'd29;
			sw20<=5'd29; sw21<=5'd30; sw22<=5'd31; sw23<=5'd31; sw24<=5'd31; sw25<=5'd30; sw26<=5'd29;
			sw30<=5'd30; sw31<=5'd30; sw32<=5'd31; sw33<=5'd31; sw34<=5'd31; sw35<=5'd30; sw36<=5'd30;
			sw40<=5'd29; sw41<=5'd30; sw42<=5'd31; sw43<=5'd31; sw44<=5'd31; sw45<=5'd30; sw46<=5'd29;
			sw50<=5'd29; sw51<=5'd30; sw52<=5'd30; sw53<=5'd30; sw54<=5'd30; sw55<=5'd30; sw56<=5'd29;
			sw60<=5'd28; sw61<=5'd29; sw62<=5'd29; sw63<=5'd30; sw64<=5'd29; sw65<=5'd29; sw66<=5'd28;
			cx0<=8'd3;  cy0<=5'd30;
			cx1<=8'd6;  cy1<=5'd26;
			cx2<=8'd10; cy2<=5'd19;
			cx3<=8'd13; cy3<=5'd13;
			cx4<=8'd17; cy4<=5'd7;
			cx5<=8'd20; cy5<=5'd4;
			cx6<=8'd23; cy6<=5'd2;
			cx7<=8'd27; cy7<=5'd1;
			cx8<=8'd30; cy8<=5'd0;
		end
		else begin
			sw00<=sw00; sw01<=sw01; sw02<=sw02; sw03<=sw03; sw04<=sw04; sw05<=sw05; sw06<=sw06;
			sw10<=sw10; sw11<=sw11; sw12<=sw12; sw13<=sw13; sw14<=sw14; sw15<=sw15; sw16<=sw16;
			sw20<=sw20; sw21<=sw21; sw22<=sw22; sw23<=sw23; sw24<=sw24; sw25<=sw25; sw26<=sw26;
			sw30<=sw30; sw31<=sw31; sw32<=sw32; sw33<=sw33; sw34<=sw34; sw35<=sw35; sw36<=sw36;
			sw40<=sw40; sw41<=sw41; sw42<=sw42; sw43<=sw43; sw44<=sw44; sw45<=sw45; sw46<=sw46;
			sw50<=sw50; sw51<=sw51; sw52<=sw52; sw53<=sw53; sw54<=sw54; sw55<=sw55; sw56<=sw56;
			sw60<=sw60; sw61<=sw61; sw62<=sw62; sw63<=sw63; sw64<=sw64; sw65<=sw65; sw66<=sw66;
			cx0<=cx0; cy0<=cy0;
			cx1<=cx1; cy1<=cy1;
			cx2<=cx2; cy2<=cy2;
			cx3<=cx3; cy3<=cy3;
			cx4<=cx4; cy4<=cy4;
			cx5<=cx5; cy5<=cy5;
			cx6<=cx6; cy6<=cy6;
			cx7<=cx7; cy7<=cy7;
			cx8<=cx8; cy8<=cy8;
		end
	end

assign space_kernel = {
					sw66,sw65,sw64,sw63,sw62,sw61,sw60,
					sw56,sw55,sw54,sw53,sw52,sw51,sw50,
					sw46,sw45,sw44,sw43,sw42,sw41,sw40,
					sw36,sw35,sw34,sw33,sw32,sw31,sw30,
					sw26,sw25,sw24,sw23,sw22,sw21,sw20,
					sw16,sw15,sw14,sw13,sw12,sw11,sw10,
					sw06,sw05,sw04,sw03,sw02,sw01,sw00};
assign color_curve_x = {
					cx8,cx7,cx6,cx5,cx4,cx3,cx2,cx1,cx0};
assign color_curve_y = {
					cy8,cy7,cy6,cy5,cy4,cy3,cy2,cy1,cy0};

endmodule //space_kernel

