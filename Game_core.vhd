library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Game_Core is
    port (
        clock       : in std_logic; -- 50MHz
        reset       : in std_logic;
        pixel_x     : in integer;
        pixel_y     : in integer;
        video_on    : in std_logic;
        v_sync_pulse: in std_logic; -- Usado para atualizar a física 1x por frame
        key_left    : in std_logic; -- Sinal processado do teclado ('A' ou Esquerda)
        key_right   : in std_logic; -- Sinal processado do teclado ('D' ou Direita)
        vga_R, vga_G, vga_B : out std_logic_vector(3 downto 0);
        score_out   : out integer range 0 to 99
    );
end entity;

architecture rtl of Game_Core is
    -- Parâmetros do Jogo
    constant PADDLE_W : integer := 80;
    constant PADDLE_H : integer := 10;
    constant PADDLE_Y : integer := 440;
    constant BALL_SIZE : integer := 10;
    
    -- Estado da Bola e Paddle
    signal ball_x : integer := 320;
    signal ball_y : integer := 400;
    signal ball_dx : integer := 4; -- Velocidade X
    signal ball_dy : integer := -4; -- Velocidade Y
    signal paddle_x : integer := 280;
    
    -- Blocos (Matriz 5 linhas x 10 colunas)
    type block_array is array(0 to 4, 0 to 9) of std_logic;
    signal blocks : block_array := (others => (others => '1')); -- '1' = ativo
    
    signal current_score : integer range 0 to 99 := 0;
    
    -- Flag para evitar atualização múltipla no mesmo frame
    signal frame_tick : std_logic := '0';
    signal last_vsync : std_logic := '0';

begin
    -- Detector de Borda de VSync para clock do jogo (60Hz) [cite: 730]
    process(clock)
    begin
        if rising_edge(clock) then
            last_vsync <= v_sync_pulse;
            if v_sync_pulse = '1' and last_vsync = '0' then
                frame_tick <= '1';
            else
                frame_tick <= '0';
            end if;
        end if;
    end process;

    -- Lógica de Movimento e Colisão
    process(clock, reset)
        variable next_x, next_y : integer;
        variable blk_col, blk_row : integer;
    begin
        if reset = '0' then
            ball_x <= 320;
            ball_y <= 400;
            ball_dy <= -4;
            paddle_x <= 280;
            current_score <= 0;
            blocks <= (others => (others => '1'));
        elsif rising_edge(clock) then
            if frame_tick = '1' then
                -- 1. Movimento do Paddle (Teclas A=Esq, D=Dir) [cite: 755]
                if key_left = '1' and paddle_x > 10 then
                    paddle_x <= paddle_x - 8;
                elsif key_right = '1' and paddle_x < (640 - PADDLE_W - 10) then
                    paddle_x <= paddle_x + 8;
                end if;

                -- 2. Movimento da Bola
                next_x := ball_x + ball_dx;
                next_y := ball_y + ball_dy;

                -- Colisão com Paredes (X)
                if next_x <= 0 or next_x >= (640 - BALL_SIZE) then
                    ball_dx <= -ball_dx;
                end if;

                -- Colisão com Teto (Y)
                if next_y <= 0 then
                    ball_dy <= -ball_dy; -- Inverte Y
                
                -- Colisão com Paddle
                elsif (next_y + BALL_SIZE) >= PADDLE_Y and 
                      (next_y + BALL_SIZE) < (PADDLE_Y + 10) and
                      (next_x + BALL_SIZE) >= paddle_x and 
                      next_x <= (paddle_x + PADDLE_W) then
                    ball_dy <= -4; -- Rebate para cima
                
                -- Game Over (Passou do fundo)
                elsif next_y > 480 then
                    ball_x <= 320; -- Reset simples
                    ball_y <= 240;
                end if;

                -- 3. Colisão com Blocos (Simples)
                -- Blocos começam em Y=50, altura 20, largura 60, gap 4
                if next_y < 150 and next_y > 50 then
                   blk_row := (next_y - 50) / 20;
                   blk_col := next_x / 64;
                   
                   if blk_row >= 0 and blk_row <= 4 and blk_col >= 0 and blk_col <= 9 then
                       if blocks(blk_row, blk_col) = '1' then
                           blocks(blk_row, blk_col) <= '0'; -- Destrói bloco
                           ball_dy <= -ball_dy; -- Rebate
                           if current_score < 99 then
                               current_score <= current_score + 1;
                           end if;
                       end if;
                   end if;
                end if;

                -- Atualiza Posição
                ball_x <= ball_x + ball_dx;
                ball_y <= ball_y + ball_dy;
            end if;
        end if;
    end process;

    score_out <= current_score;

    -- Renderização (Pipeline Gráfico)
    process(clock)
        variable blk_draw_row : integer;
        variable blk_draw_col : integer;
    begin
        if rising_edge(clock) then
            if video_on = '0' then
                vga_R <= x"0"; vga_G <= x"0"; vga_B <= x"0";
            else
                -- Desenha Bola (Branco) [cite: 590]
                if (pixel_x >= ball_x and pixel_x < ball_x + BALL_SIZE and
                    pixel_y >= ball_y and pixel_y < ball_y + BALL_SIZE) then
                    vga_R <= x"F"; vga_G <= x"F"; vga_B <= x"F";
                
                -- Desenha Paddle (Azul) [cite: 587]
                elsif (pixel_x >= paddle_x and pixel_x < paddle_x + PADDLE_W and
                       pixel_y >= PADDLE_Y and pixel_y < PADDLE_Y + PADDLE_H) then
                    vga_R <= x"0"; vga_G <= x"0"; vga_B <= x"F";

                -- Desenha Blocos (Verde/Variado)
                elsif (pixel_y >= 50 and pixel_y < 150) then
                    blk_draw_row := (pixel_y - 50) / 20;
                    blk_draw_col := pixel_x / 64;
                    -- Pequeno gap visual entre blocos
                    if ((pixel_x mod 64) > 2) and ((pixel_y - 50) mod 20 > 2) then
                        if blocks(blk_draw_row, blk_draw_col) = '1' then
                            -- Cores baseadas na linha
                            case blk_draw_row is
                                when 0 => vga_R <= x"F"; vga_G <= x"0"; vga_B <= x"0"; -- Vermelho
                                when 1 => vga_R <= x"F"; vga_G <= x"F"; vga_B <= x"0"; -- Amarelo
                                when others => vga_R <= x"0"; vga_G <= x"F"; vga_B <= x"0"; -- Verde
                            end case;
                        else
                            vga_R <= x"0"; vga_G <= x"0"; vga_B <= x"0";
                        end if;
                    else
                         vga_R <= x"0"; vga_G <= x"0"; vga_B <= x"0"; -- Gap Preto
                    end if;
                else
                    vga_R <= x"0"; vga_G <= x"0"; vga_B <= x"0"; -- Fundo Preto
                end if;
            end if;
        end if;
    end process;
end architecture;