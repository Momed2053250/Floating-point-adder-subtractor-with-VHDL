library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity fp_adder_tb is
end fp_adder_tb;

architecture test of fp_adder_tb is
  component fp_adder
    port
    (
      A     : in  std_logic_vector(31 downto 0);
      B     : in  std_logic_vector(31 downto 0);
      clk   : in  std_logic;
      reset : in  std_logic;
      start : in  std_logic;
      done  : out std_logic;
      sum   : out std_logic_vector(31 downto 0)
    );
  end component;

  

  signal A      : std_logic_vector(31 downto 0) := (others => '0');
  signal B      : std_logic_vector(31 downto 0) := (others => '0');
  signal clk    : std_logic := '0';
  signal reset  : std_logic := '1';
  signal start  : std_logic := '0';
  signal done   : std_logic;
  signal sum    : std_logic_vector(31 downto 0);

  constant CLK_PERIOD : time := 10 ns;

begin

  clk_process: process
  begin
    while now < 1000 ns loop
      clk <= '0';
      wait for CLK_PERIOD / 2;
      clk <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
    wait;
  end process clk_process;

  stimulus_process: process
  begin
    A <= "0" & "10000001" & "10000000000000000000000"; -- 1.5 * 2^2
    B <= "1" & "10000011" & "10010111000010100011111"; -- -3.54 * 2^4
    reset <= '1';
    start <= '0';
    wait for 20 ns;

    reset <= '0';
    wait for 10 ns;
    start <= '1';
    wait for 100 ns;
    start <= '0';

    wait until done = '1';

    report "Sum: " & integer'image(to_integer(unsigned(sum)));

    wait;
  end process stimulus_process;

  dut : fp_adder
    port map
    (
      A     => A,
      B     => B,
      clk   => clk,
      reset => reset,
      start => start,
      done  => done,
      sum   => sum
    );

end architecture test;

