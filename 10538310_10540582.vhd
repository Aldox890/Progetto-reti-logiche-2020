----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.02.2020 15:54:38
-- Design Name: 
-- Module Name: 10540582 - Behavioral
-- Project Name: Progetto reti logiche 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

entity project_reti_logiche is
    port (
        i_clk : in std_logic; --segnale di CLOCK in ingresso generato dal TestBench
        i_start : in std_logic; --segnale di START generato dal Test Bench
        i_rst : in std_logic; --segnale di RESET che inizializza la macchina pronta per ricevere il primo segnale di START
        i_data : in std_logic_vector(7 downto 0); --segnale (vettore) che arriva dalla memoria in seguito ad una richiesta di lettura
        o_address : out std_logic_vector(15 downto 0); --segnale (vettore) di uscita che manda l'indirizzo alla memoria
        o_done : out std_logic; --segnale di uscita che comunica la fine dell'elaborazione e il dato di uscita scritto in memoria
        o_en : out std_logic; --segnale di ENABLE da dover mandare alla memoria per poter comunicare(sia in lettura che in scrittura)
        o_we : out std_logic; --segnale di WRITE ENABLE da dover mandare alla memoria (=1) per poter scriverci. Per leggere da memoria esso deve essere 0
        o_data : out std_logic_vector (7 downto 0) --segnale (vettore) di uscita dal componente verso la memoria.
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
     type STATUS is (INIT, START, WAIT_READ, READ_DATA, CHECK_POS,SUB_POS, READ_NEW_POS, WAIT_MEM_2, CHECK_WZ, HIT_WZ, MISS_WZ, SEND_ADDRESS,DONE_STATE,END_STATE);
     signal PS, NS: STATUS;
     
     signal N_address, address: std_logic_vector(7 downto 0) := "00000000";
     signal N_current_address, current_address: std_logic_vector(3 downto 0) := "0000";
     signal N_current_Temp, current_Temp: std_logic_vector(3 downto 0) := "0000";
     signal N_o_address : std_logic_vector(15 downto 0) := "0000000000000000"; --segnale (vettore) di uscita che manda l'indirizzo alla memoria
     signal N_o_done : std_logic := '0'; --segnale di uscita che comunica la fine dell'elaborazione e il dato di uscita scritto in memoria
     signal N_o_en : std_logic := '0'; --segnale di ENABLE da dover mandare alla memoria per poter comunicare(sia in lettura che in scrittura)
     signal N_o_we : std_logic := '0'; --segnale di WRITE ENABLE da dover mandare alla memoria (=1) per poter scriverci. Per leggere da memoria esso deve essere 0
     signal N_o_data : std_logic_vector (7 downto 0):= "00000000"; --segnale (vettore) di uscita dal componente verso la memoria.
begin


delta_lambda: process( i_start,i_data, PS, address, current_address, current_Temp) --delta process della FSM
    begin
    N_address<= address;
    N_current_address <= current_address;
    N_current_Temp <= current_Temp;
    N_o_address<= "0000000000000000"; --segnale (vettore) di uscita che manda l'indirizzo alla memoria
    N_o_done <= '0'; --segnale di uscita che comunica la fine dell'elaborazione e il dato di uscita scritto in memoria
    N_o_en <= '0'; --segnale di ENABLE da dover mandare alla memoria per poter comunicare(sia in lettura che in scrittura)
    N_o_we <= '0'; --segnale di WRITE ENABLE da dover mandare alla memoria (=1) per poter scriverci. Per leggere da memoria esso deve essere 0
    N_o_data <= "00000000";
    
    case PS is
            
        when INIT =>                -- STATO INIZIALIZZAZIONE
            N_o_done <= '0';
            N_o_we <= '0';
            N_o_en <= '0';
            if i_start = '1' then   -- ATTENDO START
                NS <= START;
            else
                NS <= INIT;
            end if;
            
        when START =>               -- STATO START
            NS <= WAIT_READ;
            N_o_we <= '0';
            N_current_address <= "1000"; -- ASSEGNO STATO CELLA CORRENTE
            N_o_address <= "0000000000001000"; -- INVIO RICHIESTA INDIRIZZO CELLA 8 MEM 
            N_o_en <= '1';
            
        when WAIT_READ => -- !! RINOMINA IN WAIT_READ !!
            NS <= READ_DATA;

         
         when READ_DATA => -- STATO LETTURA INDIRIZZO CELLA 8 !! RINONOMINA IN READ_DATA !!
            NS <= CHECK_POS;
            N_address <= i_data;
            
         when CHECK_POS => -- STATO CONTROLLO ADDRESS CON CELLE 7 to 0
            N_o_we <= '0';
            if current_address > "0000" and current_address < "1001" then
                N_current_Temp <= current_address;
                NS <= SUB_POS;
            else
                NS <= MISS_WZ;  -- NON ESISTE LA WORKING ZONE
            end if;
          
         when SUB_POS =>
            NS <= READ_NEW_POS;
            N_current_address <= std_logic_vector(unsigned(current_Temp) - 1);
            
         when READ_NEW_POS => -- STATO ATTESA AGGIORNAMENTO CURRENT_ADDRESS
            N_o_address(3 downto 0) <= current_address; -- INVIO INDIRIZZO CURRENT_ADDRESS
            N_o_en <= '1';
            NS <= WAIT_MEM_2;
         
         when WAIT_MEM_2 => -- STATO ATTESA AGGIORNAMENTO i_data
            NS <= CHECK_WZ;
            
         when CHECK_WZ =>
            if unsigned(i_data) <= unsigned(address) and unsigned(address) < unsigned(i_data) + 4 then
                NS <= HIT_WZ;       -- ESISTE NELA WORKING ZONE  (cella corrente)
            else
                NS <= CHECK_POS;       -- ITERO SULLA PROSSIMA CELLA
            end if;
                

         when HIT_WZ =>     --INDIRIZZO WZ TROVATO
            case (to_integer(unsigned(address) - unsigned(i_data))) is
                when 0 =>
                    N_address(3 downto 0) <= "0001";
                when 1 =>
                    N_address(3 downto 0) <= "0010";
                when 2 =>
                    N_address(3 downto 0) <= "0100";
                when 3 =>
                    N_address(3 downto 0) <= "1000";
                when others =>
                    NS <= MISS_WZ;
            end case;
            
            N_address(7) <= '1';
            N_address(6 downto 4) <= current_address(2 downto 0);
            NS <= SEND_ADDRESS;
         
         when MISS_WZ =>    -- INDIRIZZO WZ MANCANTE
            N_address(7) <= '0'; --setto l'ottavo bit a 0
            NS <= SEND_ADDRESS;
         
         when SEND_ADDRESS =>   -- SCRIVO INDIRIZZO IN MEMORIA
            N_o_en <= '1';
            N_o_we <= '1';
            N_o_address <= "0000000000001001"; -- indirizzo 9 della RAM
            N_o_data <= address;
            NS <= DONE_STATE;
            
         when DONE_STATE =>      
            N_o_done <= '1';
            NS <= END_STATE;
         
         when END_STATE =>          -- STATO FINALE
            if i_start = '0' then
                NS <= INIT;
            else
                NS <= END_STATE;
            end if;
          
        when others =>
        NS <= INIT;
    
    end case;
   end process;
   
   -- State register
   state: process( i_clk )
   begin
       if( i_clk'event and i_clk = '1' ) then
           if( i_rst = '1' ) then
            PS <= INIT;
           else
            PS <= NS;    
            address <= N_address;
            current_address <= N_current_address;
            current_Temp <= N_current_Temp;
            o_address <= N_o_address;
            o_done <= N_o_done;
            o_en <= N_o_en;
            o_we <= N_o_we;
            o_data <= N_o_data;
           end if;
       end if;
   end process;
     
 
end Behavioral;
