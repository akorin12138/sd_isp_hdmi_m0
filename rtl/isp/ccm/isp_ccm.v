/*************************************************************************
    > File Name: isp_ccm.v
    > Author: bxq
    > Mail: 544177215@qq.com
    > Created Time: Thu 21 Jan 2021 21:50:04 GMT
 ************************************************************************/
`timescale 1 ns / 1 ps

/*
 * ISP - Color Correction Matrix
 */

module isp_ccm
#(
	parameter BITS = 8,
	parameter WIDTH = 1280,
	parameter HEIGHT = 960
)
(
	input               pclk,
	input               rst_n,

	input               in_rgb_data_en,
	input  [23:0]       in_rgb_data,
	output              out_ccm_rgb_en,
    output [23:0]       out_ccm_rgb
);
	localparam m_rr =  8'sh1a, m_rg = -8'sh05, m_rb = -8'sh05;//原仓库数值，仅参考
	localparam m_gr = -8'sh05, m_gg =  8'sh1a, m_gb = -8'sh05;//原仓库数值，仅参考
	localparam m_br = -8'sh05, m_bg = -8'sh05, m_bb =  8'sh1a;//原仓库数值，仅参考
	// [Rout]   [Mrr, Mrg, Mrb]   [Rin]
	// [Gout] = [Mgr, Mgg, Mgb] * [Gin]
	// [Bout]   [Mbr, Mbg, Mbb]   [Bin]

    wire [BITS-1:0] in_r;
    wire [BITS-1:0] in_g;
    wire [BITS-1:0] in_b;
    assign in_r = in_rgb_data[23:16];
    assign in_g = in_rgb_data[15:8];
    assign in_b = in_rgb_data[7:0];

	reg signed [BITS:0] in_r_1, in_g_1, in_b_1;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			in_r_1 <= 0;
			in_g_1 <= 0;
			in_b_1 <= 0;
		end
		else begin
			in_r_1 <= {1'b0, in_r};
			in_g_1 <= {1'b0, in_g};
			in_b_1 <= {1'b0, in_b};
		end
	end

	reg signed [BITS+8:0] data_rr, data_rg, data_rb;
	reg signed [BITS+8:0] data_gr, data_gg, data_gb;
	reg signed [BITS+8:0] data_br, data_bg, data_bb;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			data_rr <= 0;
			data_rg <= 0;
			data_rb <= 0;
			data_gr <= 0;
			data_gg <= 0;
			data_gb <= 0;
			data_br <= 0;
			data_bg <= 0;
			data_bb <= 0;
		end
		else begin
			data_rr <= m_rr * in_r_1;
			data_rg <= m_rg * in_g_1;
			data_rb <= m_rb * in_b_1;
			data_gr <= m_gr * in_r_1;
			data_gg <= m_gg * in_g_1;
			data_gb <= m_gb * in_b_1;
			data_br <= m_br * in_r_1;
			data_bg <= m_bg * in_g_1;
			data_bb <= m_bb * in_b_1;
		end
	end

	reg signed [BITS+8:0] data_r, data_g, data_b;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			data_r <= 0;
			data_g <= 0;
			data_b <= 0;
		end
		else begin
			data_r <= (data_rr + data_rg + data_rb) >>> 4;
			data_g <= (data_gr + data_gg + data_gb) >>> 4;
			data_b <= (data_br + data_bg + data_bb) >>> 4;
		end
	end

	reg [BITS-1:0] data_r_1, data_g_1, data_b_1;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			data_r_1 <= 0;
			data_g_1 <= 0;
			data_b_1 <= 0;
		end
		else begin
			data_r_1 <= data_r < 8'sd0 ? {BITS{1'b0}} : (data_r > {BITS{1'b1}} ? {BITS{1'b1}} : data_r[BITS-1:0]);
			data_g_1 <= data_g < 8'sd0 ? {BITS{1'b0}} : (data_g > {BITS{1'b1}} ? {BITS{1'b1}} : data_g[BITS-1:0]);
			data_b_1 <= data_b < 8'sd0 ? {BITS{1'b0}} : (data_b > {BITS{1'b1}} ? {BITS{1'b1}} : data_b[BITS-1:0]);
		end
	end

	localparam DLY_CLK = 4;
	reg [DLY_CLK-1:0] out_ccm_rgb_en_dly;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			out_ccm_rgb_en_dly <= 0;
		end
		else begin
			out_ccm_rgb_en_dly <= {out_ccm_rgb_en_dly[DLY_CLK-2:0], in_rgb_data_en};
		end
	end

	assign out_ccm_rgb_en = out_ccm_rgb_en_dly[DLY_CLK-1];
	// assign out_r = out_ccm_data_en ? data_r_1 : {BITS{1'b0}};
	// assign out_g = out_ccm_data_en ? data_g_1 : {BITS{1'b0}};
	// assign out_b = out_ccm_data_en ? data_b_1 : {BITS{1'b0}};
    assign out_ccm_rgb = out_ccm_rgb_en ? {data_r_1,data_g_1,data_b_1} : 24'd0;
endmodule
