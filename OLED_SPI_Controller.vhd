-- Lógica adaptada do módulo SPI da Prática 08 [cite: 445-481]
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity OLED_SPI_Controller is
    port (
        clock     : in std_logic; -- 50MHz
        reset     : in std_logic;
        score_in  : in integer range 0 to 99;
        oled_sclk : out std_logic;
        oled_mosi : out std_logic; -- DIN do OLED
        oled_dc   : out std_logic; -- Data/Command
        oled_res  : out std_logic; -- Reset
        oled_cs   : out std_logic
    );
end entity;

architecture behavioral of OLED_SPI_Controller is
    type state_type is (Idle, SendByte, WaitState);
    signal state : state_type := Idle;
    
    signal spi_clk_count : integer range 0 to 50 := 0; -- Divisor para ~1MHz SPI
    signal bit_index : integer range 0 to 7 := 7;
    signal current_byte : std_logic_vector(7 downto 0);
    signal dc_flag : std_logic := '0'; -- 0=Cmd, 1=Data
    
    -- Sequência de inicialização simplificada do SSD1306
    -- (Na prática real, esta array seria bem maior)
    type cmd_array is array (0 to 5) of std_logic_vector(7 downto 0);
    constant init_cmds : cmd_array := (x"AE", x"20", x"00", x"8D", x"14", x"AF");
    signal cmd_index : integer range 0 to 6 := 0;
    
begin
    oled_res <= reset; -- Reset direto
    oled_cs <= '0';    -- Chip Select sempre ativo (simplificado)

    process(clock, reset)
    begin
        if reset = '0' then
            state <= Idle;
            cmd_index <= 0;
            oled_sclk <= '1';
        elsif rising_edge(clock) then
            -- Gerador de Clock SPI (Bit-banging)
            if spi_clk_count = 50 then
                spi_clk_count <= 0;
                
                case state is
                    when Idle =>
                        -- Máquina de estados simples para inicialização
                        if cmd_index < 6 then
                            current_byte <= init_cmds(cmd_index);
                            dc_flag <= '0'; -- Comando
                            state <= SendByte;
                            bit_index <= 7;
                        else
                            -- Aqui enviaria o Score (representação simplificada)
                            -- Para exibir "Score", seria necessário enviar os bytes da fonte
                            -- Para fins desta resposta, o estado trava após init.
                            state <= Idle; 
                        end if;
                        
                    when SendByte =>
                        oled_dc <= dc_flag;
                        oled_mosi <= current_byte(bit_index);
                        oled_sclk <= '0'; -- Borda de descida coloca o dado
                        state <= WaitState;
                        
                    when WaitState =>
                        oled_sclk <= '1'; -- Borda de subida latcha o dado
                        if bit_index = 0 then
                            state <= Idle;
                            if cmd_index < 6 then cmd_index <= cmd_index + 1; end if;
                        else
                            bit_index <= bit_index - 1;
                            state <= SendByte;
                        end if;
                end case;
            else
                spi_clk_count <= spi_clk_count + 1;
            end if;
        end if;
    end process;
end architecture;