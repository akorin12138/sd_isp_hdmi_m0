module gamma_top(
    input  wire         gamma_en,
    input  wire [23:0]  pre_rgb_data,
    input  wire         pre_rgb_en,
    output wire [23:0]  post_rgb_data,
    output wire         post_rgb_en
);
    wire [7:0] r,r_g;
    wire [7:0] g,g_g;
    wire [7:0] b,b_g;

    assign r = pre_rgb_data[23:16];
    assign g = pre_rgb_data[15:8];
    assign b = pre_rgb_data[7:0];

    Gamma u_Gammar(
        .en         ( gamma_en ),
        .Pre_Data   ( r        ),
        .Post_Data  ( r_g      )
    );
    Gamma u_Gammag(
        .en         ( gamma_en ),
        .Pre_Data   ( g        ),
        .Post_Data  ( g_g      )
    );
    Gamma u_Gammab(
        .en         ( gamma_en ),
        .Pre_Data   ( b        ),
        .Post_Data  ( b_g      )
    );
    assign post_rgb_data = {r_g,g_g,b_g};
    assign post_rgb_en = pre_rgb_en;
endmodule //gamma_top

