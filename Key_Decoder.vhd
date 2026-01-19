library ieee;
use ieee.std_logic_1164.all;

entity Key_Decoder is
    port (
        clock     : in std_logic;
        makecode  : in std_logic_vector(7 downto 0);
        breakcode : in std_logic_vector(7 downto 0);
        key_left  : out std_logic; 
        key_right : out std_logic  
    );
end entity;

architecture logic of Key_Decoder is
    signal s_left, s_right : std_logic := '0';
begin
    process(clock)
    begin
        if rising_edge(clock) then
            -- Lógica Esquerda (Prioridade para parar o movimento)
            if breakcode = x"1C" then 
                s_left <= '0';
            elsif makecode = x"1C" then 
                s_left <= '1'; 
            end if;

            -- Lógica Direita (Prioridade para parar o movimento)
            if breakcode = x"23" then 
                s_right <= '0';
            elsif makecode = x"23" then 
                s_right <= '1'; 
            end if;
        end if;
    end process;

    key_left  <= s_left;
    key_right <= s_right;
end architecture;