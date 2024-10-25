library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity signed_subtractor is
  port (
    a: in signed(8 downto 0);
    b: in signed(8 downto 0);
    c_in: in std_logic;
    s: out signed(8 downto 0);
    Ovrf: out std_logic
  );
end signed_subtractor;

architecture BEHAVIORAL of signed_subtractor is

  component FullSubtractor is
    port (
      a: in std_logic;
      b: in std_logic;
      c_in: in std_logic;
      s: out std_logic;
      c_out: out std_logic
    );
  end component;

  signal inverted_c_in : std_logic;
  signal tc : signed(8 downto 0);

begin
  inverted_c_in <= not c_in;  -- Invert carry-in for subtraction

  First_FS: FullSubtractor
    port map (
      a => a(0),
      b => b(0),
      c_in => inverted_c_in,
      s => s(0),
      c_out => tc(0)
    );

  SUBTRACTOR_GEN: for i in 8 downto 1 generate
    FS: FullSubtractor
      port map
      (
        a => a(i),
        b => b(i),
        c_in => tc(i-1),
        s => s(i),
        c_out => tc(i)
      );
  end generate SUBTRACTOR_GEN;

  Ovrf <= '1' when (tc(8) = '1') else '0';

end BEHAVIORAL;

