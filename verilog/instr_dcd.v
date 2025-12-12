module instr_dcd (
    // peripheral clock signals
    input clk,
    input rst_n,
    // towards SPI slave interface signals
    input byte_sync,
    input [7:0] data_in,
    output [7:0] data_out,
    // register access signals
    output read,
    output write,
    output [5:0] addr,
    input [7:0] data_read,
    output [7:0] data_write
);

// FSM -> 2 stari: 0 = astept setup byte, 1 = astept data byte
reg state;

localparam STATE_SETUP = 1'b0;
localparam STATE_DATA  = 1'b1;

// informatii pe care le memoram din primul byte
reg rw_bit;        // bitul 7: 1 = write, 0 = read
reg high_low;   // bitul 6: 1 = MSB, 0 = LSB

// redeclararea porturilor output ca reg pentru a le putea folosi in blocuri always
reg read_r;
reg write_r;
reg [5:0] addr_r;
reg [7:0] data_out_r;
reg [7:0] data_write_r;

// registre pentru sincronizare si detectie front
reg byte_sync_d1;
reg byte_sync_d2;
reg byte_sync_d3;

// legam output-urile modulului de registrele interne
assign read = read_r;
assign write = write_r;
assign addr = addr_r;
assign data_out = data_out_r;
assign data_write = data_write_r;

// pe frontul crescator al semnalului de ceas sau frontul descrescator al semnalului rst_n
always @(posedge clk or negedge rst_n) begin
    // daca rst_n e activ, registrele sunt intr-o stare sigura (zero)
    if (!rst_n) begin
        state <= STATE_SETUP;
        read_r <= 1'b0;
        write_r <= 1'b0;
        addr_r <= 6'd0;
        data_out_r <= 8'd0;
        data_write_r <= 8'd0;
        rw_bit <= 1'b0;
        high_low <= 1'b0;
        
        // resetare sincronizator
        byte_sync_d1 <= 1'b0;
        byte_sync_d2 <= 1'b0;
        byte_sync_d3 <= 1'b0;
    end else begin
        // la fiecare ciclu de ceas resetam read si write
        read_r  <= 1'b0;
        write_r <= 1'b0;
        
        // sincronizam byte_sync in domeniul de ceas clk
        byte_sync_d1 <= byte_sync; // sincronizare: protectie metastabilitate
        byte_sync_d2 <= byte_sync_d1; // starea curenta (stabila)
        byte_sync_d3 <= byte_sync_d2; // starea anterioara (intarziata cu un ciclu)

        // detectam frontul crescator: a fost 0, acum este 1
        if (byte_sync_d2 && !byte_sync_d3) begin
            
            case (state)
                // 1. Faza de setup
                STATE_SETUP: begin
                    rw_bit   <= data_in[7];
                    high_low <= data_in[6];
                    addr_r   <= data_in[5:0]; // adresa
                    state    <= STATE_DATA; // trecem la faza de date
                end
                
                // 2. Faza de date
                STATE_DATA: begin
                    if (rw_bit) begin
                        data_write_r <= data_in; // scrie byte-ul primit de la SPI în registru 
                        write_r <= 1'b1; 
                    end else begin
                        data_out_r <= data_read; // pune byte-ul din registru în data_out_r (va fi trimis la SPI)
                        read_r <= 1'b1;
                    end
                    state <= STATE_SETUP; // revenim la asteptarea urmatoarei instructiuni
                end
            endcase
        end
     end
 end

endmodule
