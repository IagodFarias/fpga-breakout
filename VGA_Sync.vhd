-- Fonte: Prática 05 - VGA, Anexos I [cite: 783]
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_Sync is
    generic (
        -- Constantes definidas na Prática 05 [cite: 803-809]
        h_total : integer := 800;
        v_total : integer := 525;
        h_retrace : integer := 96;
        v_retrace : integer := 2;
        h_backporch : integer := 48;
        v_topborder : integer := 33 -- Backporch vertical + top border
    );
    port (
        pixel_clock : in std_logic;
        vga_hs      : out std_logic;
        vga_vs      : out std_logic;
        pixel_x     : out integer; -- Coordenada X visível
        pixel_y     : out integer; -- Coordenada Y visível
        video_on    : out std_logic -- Indica se está na área ativa
    );
end entity;

architecture rtl of VGA_Sync is
    signal h_count : integer range 0 to h_total := 0;
    signal v_count : integer range 0 to v_total := 0;
    signal v_clk   : std_logic := '0'; -- Clock virtual para o contador vertical
begin

    -- Sincronismo Horizontal [cite: 818]
    process(pixel_clock)
    begin
        if rising_edge(pixel_clock) then
            if h_count = h_total - 1 then
                h_count <= 0;
                v_clk <= '1'; -- Pulso para incrementar vertical
            else
                h_count <= h_count + 1;
                v_clk <= '0';
            end if;

            -- Gera HSync (Ativo em nível baixo durante o retrace)
            if h_count < h_retrace then
                vga_hs <= '0';
            else
                vga_hs <= '1';
            end if;
        end if;
    end process;

    -- Sincronismo Vertical [cite: 834]
    process(pixel_clock) -- Usando pixel_clock síncrono com enable via v_clk
    begin
        if rising_edge(pixel_clock) then
            if v_clk = '1' then
                if v_count = v_total - 1 then
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
                end if;

                -- Gera VSync (Ativo em nível baixo)
                if v_count < v_retrace then
                    vga_vs <= '0';
                else
                    vga_vs <= '1';
                end if;
            end if;
        end if;
    end process;

    -- Calcula coordenadas ativas e sinal video_on
    -- As constantes de offset são baseadas no diagrama da Figura 8 [cite: 722]
    process(h_count, v_count)
        variable x_raw : integer;
        variable y_raw : integer;
    begin
        x_raw := h_count - (h_retrace + h_backporch);
        y_raw := v_count - (v_retrace + v_topborder);

        if (x_raw >= 0 and x_raw < 640 and y_raw >= 0 and y_raw < 480) then
            video_on <= '1';
            pixel_x <= x_raw;
            pixel_y <= y_raw;
        else
            video_on <= '0';
            pixel_x <= 0;
            pixel_y <= 0;
        end if;
    end process;

end architecture;