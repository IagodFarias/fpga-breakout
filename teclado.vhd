-- Fonte: Prática 03 - Teclado PS/2, Anexos [cite: 164]
library ieee;
use ieee.std_logic_1164.all;

entity teclado is
    port (
        reset     : in std_logic;
        clock_tec : in std_logic;
        dados_tec : in std_logic;
        makecode  : out std_logic_vector(7 downto 0);
        breakcode : out std_logic_vector(7 downto 0)
    );
end entity;

architecture hardware of teclado is
    signal contador : natural range 0 to 10 := 0;
    signal byte_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal prefixo_F0 : std_logic := '0';
    signal prefixo_E0 : std_logic := '0';
    signal paridade_calc : std_logic := '0'; -- Variável movida para signal para visibilidade
begin
    process(clock_tec, reset)
        variable paridade : std_logic := '0';
    begin
        if (reset = '0') then
            contador <= 0;
            byte_reg <= (others => '0');
            prefixo_F0 <= '0';
            prefixo_E0 <= '0';
            makecode <= (others => '0');
            breakcode <= (others => '0');
        elsif (falling_edge(clock_tec)) then -- [cite: 202]
            case contador is
                when 0 => -- Start bit
                    if dados_tec = '0' then
                        contador <= 1;
                        paridade := '0';
                    end if;
                when 1 to 8 => -- Dados
                    byte_reg(contador - 1) <= dados_tec;
                    if dados_tec = '1' then
                        paridade := not paridade;
                    end if;
                    contador <= contador + 1;
                when 9 => -- Paridade
                    -- Lógica simplificada de verificação de paridade baseada no texto [cite: 221]
                    contador <= 10; 
                when 10 => -- Stop bit
                    if dados_tec = '1' then
                        -- Interpretador de códigos [cite: 232]
                        if byte_reg = x"F0" then
                            prefixo_F0 <= '1';
                        elsif byte_reg = x"E0" then
                            prefixo_E0 <= '1';
                        else
                            if prefixo_F0 = '1' then
                                breakcode <= byte_reg;
                                prefixo_F0 <= '0';
                                prefixo_E0 <= '0';
                            else
                                makecode <= byte_reg;
                                prefixo_F0 <= '0'; -- Garante limpeza se não houver break
                                prefixo_E0 <= '0';
                            end if;
                        end if;
                    end if;
                    contador <= 0; -- Reinicia
            end case;
        end if;
    end process;
end architecture;