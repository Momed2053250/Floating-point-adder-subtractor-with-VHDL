library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity FOUR_BIT_ADDER is
port (	a: in std_logic_vector(22 downto 0);
	b: in std_logic_vector(22 downto 0);
	c_in: in std_logic;
	s: out std_logic_vector(22 downto 0);
        Ovrf: out std_logic);
end FOUR_BIT_ADDER;

architecture BEHAVIORAL of FOUR_BIT_ADDER is 	

component FullAdder
port (	a: in std_logic;
	b: in std_logic;
	c_in: in std_logic;
	s: out std_logic;
        c_out: out std_logic);
end component;

signal tc : std_logic_vector(22 downto 0);
begin
First_FA: FullAdder
  port map (
    a => a(0),
    b => b(0),
    c_in => c_in,
    s => s(0),
    c_out => tc(0));

ADDER_GEN: for i in 22 downto 1 generate
FA: FullAdder
  port map
  (a => a(i),
   b => b(i),
   c_in => tc(i-1),
   s =>s(i),
   c_out => tc(i));
end generate ADDER_GEN;

Ovrf <= '1' when (tc(22) = '1') else '0';

end BEHAVIORAL;					
