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

// informatii pe care le memoram din primul byte
reg rw_bit;     // bitul 7: 1 = write, 0 = read
reg high_low;   // bitul 6: 1 = MSB, 0 = LSB

// redeclararea porturilor output ca reg pentru a le putea folosi in blocuri always
reg read_r;
reg write_r;
reg [5:0] addr_r;
reg [7:0] data_out_r;
reg [7:0] data_write_r;

// legam output-urile modulului de registrele intern
assign read = read_r;
assign write = write_r;
assign addr = addr_r;
assign data_out = data_out_r;
assign data_write = data_write_r;

// pe frontul crescator al semnalului de ceas sau frontul descrescator al semnalului rst_n
always @(posedge clk or negedge rst_n) begin
    // daca rst_n e activ, registrele sunt intr-o stare sigura (zero)
    if (!rst_n) begin
        state <= 1'b0;
        read_r <= 1'b0;
        write_r <= 1'b0;
        addr_r <= 6'd0;
        data_out_r <= 8'd0;
        data_write_r <= 8'd0;
        rw_bit <= 1'b0;
        high_low <= 1'b0;
    end else begin
    
        // la fiecare ciclu de ceas resetam read si write
        read_r  <= 1'b0;
        write_r <= 1'b0;
        
        // daca avem un byte complet
        if (byte_sync) begin
            case (state)
            
            // 1. Faza de setup
            1'b0: begin
                rw_bit   <= data_in[7];
                high_low <= data_in[6];
                addr_r   <= data_in[5:0];  // adresa
                
                state <= 1'b1; // trecem la faza de date
            end
            
            // 2. Faza de date
            1'b1: begin
                if (rw_bit) begin
                    data_write_r <= data_in; // scrie byte-ul primit de la SPI în registru 
                    write_r <= 1'b1; 
                end else begin
                    data_out_r <= data_read; // pune byte-ul din registru în data_out_r (va fi trimis la SPI)
                    read_r <= 1'b1;
                end
                
                state <= 1'b0; // revenim la asteptarea urmatoarei instructiuni
            end
            
            endcase
        end
     end
 end

endmodule
