library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity FullSubtractor is
port (
  a: in std_logic;
  b: in std_logic;
  c_in: in std_logic;
  s: out std_logic;
  c_out: out std_logic
);
end FullSubtractor;

architecture BEHAVIORAL of FullSubtractor is

  signal sig_s: std_logic := '0';

begin

  -- a   b   bi  D   bo
  -- 0   0   0   0   0
  -- 0   0   1   1   1
  -- 1   0   0   1   0
  -- 1   0   1   0   0
  -- 0   1   0   1   1
  -- 0   1   1   0   1
  -- 1   1   0   0   0
  -- 1   1   1   1   0

  sig_s <= a xor b xor c_in;
  c_out <= (not b and c_in) or (not (a xor b) and a);

  s <= sig_s;

end BEHAVIORAL;

