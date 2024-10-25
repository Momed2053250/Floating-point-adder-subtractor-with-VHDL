library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity FullAdder is
port (	a: in std_logic;
	b: in std_logic;
	c_in: in std_logic;
	s: out std_logic;
        c_out: out std_logic);
end FullAdder;

architecture BEHAVIORAL of FullAdder is

signal sig_s: std_logic:='0';  
  
begin

-- a   b   ci  S   co
-- 0   0   0   0   0   
-- 0   0   1   1   0   
-- 1   0   0   1   0   
-- 1   0   1   0   1   
-- 0   1   0   1   0   
-- 0   1   1   0   1   
-- 1   1   0   0   1   
-- 1   1   1   1   1
--
--
sig_s <= a xor b xor c_in;
c_out <= (b and c_in) or (a and b) or (a and c_in);

s <= sig_s;

end BEHAVIORAL;					
