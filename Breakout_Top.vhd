library ieee;
use ieee.std_logic_1164.all;

entity Breakout_Top is
    port (
        CLOCK_50  : in std_logic;
        -- Teclas (Prática 03)
        PS2_CLK   : in std_logic; -- PIN H15 [cite: 269]
        PS2_DAT   : in std_logic; -- PIN J14 [cite: 270]
        KEY_RESET : in std_logic; -- Reset (Botão do kit)
        
        -- VGA (Prática 05)
        VGA_HS    : out std_logic; -- PIN A11 [cite: 1170]
        VGA_VS    : out std_logic; -- PIN B11 [cite: 1173]
        VGA_R     : out std_logic_vector(3 downto 0); -- [cite: 1134]
        VGA_G     : out std_logic_vector(3 downto 0);
        VGA_B     : out std_logic_vector(3 downto 0);
        
        -- OLED (Pinos genéricos GPIO)
        OLED_SCLK : out std_logic;
        OLED_MOSI : out std_logic;
        OLED_DC   : out std_logic;
        OLED_RES  : out std_logic;
        OLED_CS   : out std_logic
    );
end entity;

architecture struct of Breakout_Top is
    signal clk_25 : std_logic;
    
    -- Sinais PS/2
    signal mk_code, bk_code : std_logic_vector(7 downto 0);
    signal move_left, move_right : std_logic := '0';
    
    -- Sinais VGA
    signal px, py : integer;
    signal video_active, vsync_internal : std_logic;
    
    -- Score
    signal score_val : integer range 0 to 99;

begin
    -- 1. Instância do Divisor de Clock
    U1: entity work.divisor port map (
        clock => CLOCK_50,
        pixel_clock => clk_25
    );

    -- 2. Instância do Teclado PS/2
    U2: entity work.teclado port map (
        reset => KEY_RESET,
        clock_tec => PS2_CLK,
        dados_tec => PS2_DAT,
        makecode => mk_code,
        breakcode => bk_code
    );

    -- Lógica de Controle do Jogador (Latch)
    -- 'A' = 1C, 'D' = 23 (Hex) [cite: 122]
    process(CLOCK_50)
    begin
        if rising_edge(CLOCK_50) then
            if mk_code = x"1C" then move_left <= '1'; end if; -- Pressionou A
            if bk_code = x"1C" then move_left <= '0'; end if; -- Soltou A
            
            if mk_code = x"23" then move_right <= '1'; end if; -- Pressionou D
            if bk_code = x"23" then move_right <= '0'; end if; -- Soltou D
        end if;
    end process;

    -- 3. Instância do Sincronismo VGA
    U3: entity work.VGA_Sync port map (
        pixel_clock => clk_25,
        vga_hs => VGA_HS,
        vga_vs => vsync_internal,
        pixel_x => px,
        pixel_y => py,
        video_on => video_active
    );
    VGA_VS <= vsync_internal;

    -- 4. Instância do Núcleo do Jogo
    U4: entity work.Game_Core port map (
        clock => clk_25,
        reset => KEY_RESET,
        pixel_x => px,
        pixel_y => py,
        video_on => video_active,
        v_sync_pulse => vsync_internal,
        key_left => move_left,
        key_right => move_right,
        vga_R => VGA_R,
        vga_G => VGA_G,
        vga_B => VGA_B,
        score_out => score_val
    );
    
    -- 5. Instância do OLED Controller
    U5: entity work.OLED_SPI_Controller port map (
        clock => CLOCK_50,
        reset => KEY_RESET,
        score_in => score_val,
        oled_sclk => OLED_SCLK,
        oled_mosi => OLED_MOSI,
        oled_dc => OLED_DC,
        oled_res => OLED_RES,
        oled_cs => OLED_CS
    );

end architecture;