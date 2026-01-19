-- Fonte: Prática 05 - VGA, Anexos I [cite: 761]
library ieee;
use ieee.std_logic_1164.all;

entity divisor is
    port (
        clock       : in std_logic;      -- Clock de 50 MHz
        pixel_clock : buffer std_logic   -- Clock de 25 MHz
    );
end entity;

architecture rtl of divisor is
begin
    process (clock)
    begin
        if rising_edge (clock) then
            pixel_clock <= not pixel_clock;
        end if;
    end process;
end architecture;