library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
port (
    i_clk : in std_logic;
    i_rst : in std_logic;
    i_start : in std_logic;
    i_data : in std_logic_vector(7 downto 0);
    o_address : out std_logic_vector(15 downto 0);
    o_done : out std_logic;
    o_en : out std_logic;
    o_we : out std_logic;
    o_data : out std_logic_vector (7 downto 0)
);
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

type state is ( IDLE,
                READ_LENGTH,
                CHECK_COUNT,
                READ_VALUE,
                SHIFT_VALUE,
                COMPUTE,
                COMPUTE_END,
                WRITE,
                SET_DONE    );


signal data, data_next : STD_LOGIC_VECTOR(7 downto 0) := "00000000";

signal o_done_next: STD_LOGIC := '0'; 

signal state_prox : state;
signal state_curr : state;

signal in_address, in_address_temp: STD_LOGIC_VECTOR(15 downto 0) := "0000000000000000";
signal out_address, out_address_temp: STD_LOGIC_VECTOR(15 downto 0) := "0000001111101000";

signal length, length_temp: STD_LOGIC_VECTOR(7 downto 0) := "00000000";
signal data_in, data_in_temp: STD_LOGIC_VECTOR(7 downto 0) := "00000000";

signal count_words, count_words_temp : INTEGER range 0 to 255 := 0;
signal bit_to_evaluate, bit_temp : INTEGER range 0 to 4 := 4;
signal word_to_complete, word_temp: INTEGER range 0 to 1 := 1;

signal uk, uk_temp, uk1, uk1_temp, uk2, uk2_temp: STD_LOGIC := '0';


begin
process (i_clk, i_rst)
begin
    if (i_rst = '1') then        
        out_address <= "0000001111101000";
        in_address <= "0000000000000000";        
        length <= "00000000";
        data_in <= "00000000"; 
        data <= "00000000";      
        count_words <= 0;
        bit_to_evaluate <= 4;
        word_to_complete <= 1;
        uk <= '0';
        uk1 <= '0';
        uk2 <= '0';              
        state_curr <= IDLE;
        
    elsif (i_clk'event and i_clk = '1') then
        o_done <= o_done_next;
        
        uk <= uk_temp;
        uk1 <= uk1_temp;
        uk2 <= uk2_temp;
        data <= data_next;
        in_address <= in_address_temp;
        out_address <= out_address_temp;
        word_to_complete <= word_temp;
        bit_to_evaluate <= bit_temp;
        count_words <= count_words_temp;
        length <= length_temp;
        data_in <= data_in_temp;
        
        state_curr <= state_prox;
    end if;
end process;

process(i_start, data, i_data, state_curr, uk, uk1, uk2, in_address, out_address, word_to_complete, bit_to_evaluate, count_words, length, data_in)
begin
    o_done_next <= '0';
    o_en <= '0';
    o_we <= '0';
    o_data <= "00000000";
    o_address <= "0000000000000000";
      
    data_next <= data;   
    uk_temp <= uk;
    uk1_temp <= uk1;
    uk2_temp <= uk2;
    out_address_temp <= out_address;
    in_address_temp <= in_address;
    word_temp <= word_to_complete;
    bit_temp <= bit_to_evaluate;
    count_words_temp <= count_words;
    length_temp <= length;
    data_in_temp <= data_in;
    
    state_prox <= state_curr;    
        
        case state_curr is
            when IDLE => if (i_start = '1') then
                            o_en <= '1'; 
                            state_prox <= READ_LENGTH;
                         end if;

            when READ_LENGTH => length_temp <= i_data;
                                state_prox <= CHECK_COUNT;
                                
            when CHECK_COUNT => if (count_words >= to_integer(unsigned(length))) then
                                o_done_next <= '1';
                                state_prox <= SET_DONE;
                              else
                                o_en <= '1';
                                in_address_temp <= std_logic_vector(unsigned(in_address) + 1);
                                o_address <= std_logic_vector(unsigned(in_address) + 1);
                                state_prox <= READ_VALUE;
                              end if;
                                          
            when READ_VALUE => data_in_temp <= i_data;
                               bit_temp <= bit_to_evaluate - 1;
                               state_prox <= SHIFT_VALUE;
                               
            when SHIFT_VALUE => uk_temp <= data_in(bit_to_evaluate + word_to_complete*4);
                                uk1_temp <= uk;
                                uk2_temp <= uk1;
                                state_prox <= COMPUTE;
                                  
            when COMPUTE => data_next(bit_to_evaluate*2 + 1) <= uk XOR uk2;
                            data_next(bit_to_evaluate*2) <= (uk XOR uk1) XOR uk2;
                            state_prox <= COMPUTE_END;                                  
                                   
            when COMPUTE_END => if (bit_to_evaluate <= 0) then                                                                                                          
                                    bit_temp <= 4;
                                    state_prox <= WRITE;
                                else
                                    bit_temp <= bit_to_evaluate - 1;
                                    state_prox <= SHIFT_VALUE;
                                end if;
                               
            when WRITE => out_address_temp <= std_logic_vector(unsigned(out_address) + 1);
                          o_en <= '1';
                          o_we <= '1';
                          o_data <= data;
                          o_address <= out_address;
                          if (word_to_complete <= 0) then
                            word_temp <= 1; 
                            count_words_temp <= count_words + 1;
                            state_prox <= CHECK_COUNT;
                          else
                            bit_temp <= bit_to_evaluate - 1;
                            word_temp <= word_to_complete - 1;                       
                            state_prox <= SHIFT_VALUE;
                          end if;
                          
            when SET_DONE => if (i_start = '0') then
                                o_done_next <= '0';
                                out_address_temp <= "0000001111101000";
                                in_address_temp <= "0000000000000000";
                                data_in_temp <= "00000000";
                                length_temp <= "00000000";
                                count_words_temp <= 0;
                                uk_temp <= '0';
                                uk1_temp <= '0';
                                uk2_temp <= '0';
                                bit_temp <= 4;
                                word_temp <= 1;
                                
                                state_prox <= IDLE;
                             end if; 
                                  
        end case;
end process;

end Behavioral;
